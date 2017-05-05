defmodule Farmbot.System.Network do
  @moduledoc """
    Network functionality.
  """
  require Logger
  use GenServer
  alias Farmbot.System.FS.ConfigStorage, as: CS
  alias Farmbot.System.Network.SSH
  alias Farmbot.System.Network.Ntp
  alias Farmbot.Auth

  @spec mod(atom) :: atom
  defp mod(target), do: Module.concat([Farmbot, System, target, Network])

  def init(target) do
    Logger.info ">> is starting networking"
    m = mod(target)
    {:ok, _cb} = m.start_link
    {:ok, interface_config} = get_config("interfaces")
    parse_and_start_config(interface_config, m)
    {:ok, target}
  end

  # if networking is disabled.
  defp parse_and_start_config(nil, _), do: spawn(fn ->
    Process.sleep(2000)
    spawn fn ->
      maybe_get_fpf()
    end

    Farmbot.Auth.try_log_in
  end)

  defp parse_and_start_config(config, m) do
    for {interface, settings} <- config do
        m.start_interface(interface, settings)
    end
  end

  defp maybe_get_fpf do
    {:ok, fpf} = GenServer.call(CS, {:get, Configuration, "first_party_farmware"})
    if fpf, do: Farmware.get_first_party_farmware
  end

  @doc """
    Starts the network manager
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
    Scans for wireless ssids.
  """
  @spec scan(String.t) :: [String.t]
  def scan(interface_name) do
    GenServer.call(__MODULE__, {:scan, interface_name})
  end

  @doc """
    Lists all network interfaces that Farmbot Detected.
  """
  @spec enumerate :: [String.t] | {:error, term}
  def enumerate do
    GenServer.call(__MODULE__, :enumerate)
  end

  @doc """
    Restarts networking services. This will block.
  """
  def restart do
    stop_all()
    {:ok, interface_config} = get_config("interfaces")
    m = mod(get_mod()) # wtf is this?
    parse_and_start_config(interface_config, m)
  end

  @doc """
    Starts an interface
  """
  def start_interface(interface, settings) do
    GenServer.call(__MODULE__, {:start, interface, settings}, :infinity)
  end

  @doc """
    Stops an interface
  """
  def stop_interface(interface) do
    GenServer.call(__MODULE__, {:stop, interface}, :infinity)
  end

  @doc """
    Stops all interfaces
  """
  def stop_all do
    {:ok, interfaces} = get_config("interfaces")
    if interfaces do
      for {iface, _} <- interfaces do
        stop_interface(iface)
      end
    end
  end

  defp maybe_set_time do
    {:ok, ntp} = get_config("ntp")
    if ntp do
      Logger.info ">> starting ntp client."
      Ntp.set_time
    end
    :ok
  end

  defp maybe_start_ssh do
    {:ok, ssh} = get_config("ssh")
    try do
      if ssh do
        Logger.info ">> starting SSH server."
        spawn SSH, :start_link, []
      end
      :ok
    rescue
      error ->
        Logger.warn(">> Failed to start ssh: #{inspect error}")
        :ok
    end
  end

  defp maybe_get_fpf do
    # First Party Farmware is not really a network concern but here we are...
    {:ok, fpf} = GenServer.call(CS, {:get, Configuration, "first_party_farmware"})

    try do
      if fpf do
        Logger.info ">> is installing first party Farmwares."
        Farmware.get_first_party_farmware
      end
      :ok
    rescue
      error ->
        Logger.warn(">> Failed to install farmwares: #{inspect error}")
        :ok
    end
  end

  @doc """
    Connected to the World Wide Web. Should be called from the
    callback module.
  """
  def on_connect(pre_fun \\ nil, post_fun \\ nil) do
    # Start the Downloader http client.
    Supervisor.start_child(Farmbot.System.Supervisor,
      Supervisor.Spec.worker(Downloader, [], [restart: :permanent]))

    # this happens because on wifi we try to do stuff before linux is
    # finished setting stuff up.
    Process.sleep(2000)

    # If we were supplied a pre connect callback, do that.
    if pre_fun, do: pre_fun.()

    Logger.info ">> is connected to the World Wide Web."

    :ok = maybe_set_time()
    :ok = maybe_start_ssh()
    :ok = maybe_get_fpf()

    Logger.info ">> is trying to log in."
    {:ok, token} = Auth.try_log_in!

    :ok = maybe_setup_rollbar(token)

    if post_fun do
      post_fun.(token)
    end

    {:ok, token}
  end

  if Mix.env == :prod do

    # Only set these attributes if we are in prod pls
    @access_token Application.get_env(:farmbot, :rollbar_access_token)
    @commit Mix.Project.config[:commit]
    @target Mix.Project.config[:target]

    def maybe_setup_rollbar(token) do
      if String.contains?(token.unencoded.iss, "farmbot.io") and @access_token do
        Logger.info ">> Setting up rollbar!"
        :ok = ExRollbar.setup access_token: @access_token,
          environment: token.unencoded.iss,
          enable_logger: true,
          person_id: token.unencoded.bot,
          person_email: token.unencoded.sub,
          person_username: token.unencoded.bot,
          framework: "Nerves",
          code_version: @commit,
          custom: %{target: @target}
        :ok
      else
        Logger.info ">> Not Setting up rollbar!"
        :ok
      end
    end

  else

    def maybe_setup_rollbar(_), do: Logger.info ">> Not Setting up rollbar!"

  end

  @spec get_config(String.t) :: {:ok, any}
  defp get_config(key), do: GenServer.call(CS, {:get, Network, key})
  # @spec get_config() :: {:ok, false | map}
  # defp get_config, do: GenServer.call(CS, {:get, Network, :all})

  defp get_mod, do: GenServer.call(__MODULE__, :get_mod)

  # GENSERVER STUFF
  def handle_call(:get_mod, _, target), do: {:reply, target, target}
  def handle_call({:scan, interface_name}, _, target) do
     f = mod(target).scan(interface_name)
     {:reply, f, target}
  end

  def handle_call(:enumerate, _, target) do
    f = mod(target).enumerate
    {:reply, f, target}
  end

  def handle_call({:start, interface, settings}, _, target) do
    f = mod(target).start_interface(interface, settings)
    {:reply, f, target}
  end

  def handle_call({:stop, interface}, _, target) do
    f = mod(target).stop_interface(interface)
    {:reply, f, target}
  end

  def terminate(reason, target) do
    ssh_pid = Process.whereis(SSH)
    if ssh_pid do
       SSH.stop(reason)
    end
    target_pid = Process.whereis(mod(target))
    if target_pid do
      GenServer.stop(target_pid, reason)
    end
  end

  # Behavior
  @type return_type :: :ok | {:error, term}
  @callback scan(String.t) :: [String.t] | {:error, term}
  @callback enumerate() :: [String.t] | {:error, term}
  @callback start_interface(String.t, map) :: return_type
  @callback stop_interface(String.t) :: return_type
  @callback start_link :: {:ok, pid}
end
