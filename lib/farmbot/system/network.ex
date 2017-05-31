defmodule Farmbot.System.Network do
  @moduledoc """
    Network functionality.
  """
  require Logger
  use GenServer
  alias Farmbot.System.FS.ConfigStorage, as: CS
  alias Farmbot.System.Network.{Ntp, SSH}
  alias Farmbot.{Context, Auth}
  use Farmbot.DebugLog

  @type netman :: pid

  @spec mod(atom | binary | Context.t) :: atom
  defp mod(%Context{} = context), do: mod(context.network)
  defp mod(target) when is_atom(target) or is_binary(target),
    do: Module.concat([Farmbot, System, target, Network])

  @doc """
    Starts the network manager
  """
  def start_link(%Context{} = context, target, opts) do
    GenServer.start_link(__MODULE__, [context, target], opts)
  end

  def init([%Context{} = context, target]) do
    Logger.info ">> is starting networking"
    m = mod(target)
    {:ok, _cb} = m.start_link(context)
    {:ok, interface_config} = get_config("interfaces")
    parse_and_start_config(context, interface_config, m)
    {:ok, %{context: context, target: target}}
  end

  # if networking is disabled.
  defp parse_and_start_config(%Context{} = context, nil, _), do: spawn(fn ->
    Process.sleep(2000)
    spawn fn ->
      maybe_get_fpf(context)
    end
    maybe_log_in(context)
  end)

  defp parse_and_start_config(%Context{} = context, config, m) do
    for {interface, settings} <- config do
        m.start_interface(context, interface, settings)
    end
  end

  case Mix.env do
    :test -> defp maybe_log_in(_ctx), do: :ok
    _     -> defp maybe_log_in(ctx), do: Farmbot.Auth.try_log_in(ctx.auth)
  end

  @doc """
    Scans for wireless ssids.
  """
  @spec scan(netman, binary) :: [binary]
  def scan(netman, interface_name) do
    GenServer.call(netman, {:scan, interface_name})
  end

  @doc """
    Lists all network interfaces that Farmbot Detected.
  """
  @spec enumerate(netman) :: [binary] | {:error, term}
  def enumerate(netman) do
    GenServer.call(netman, :enumerate)
  end

  @doc """
    Restarts networking services. This will block.
  """
  def restart(netman) when is_atom(netman) or is_pid(netman) do
    stop_all(netman)
    {:ok, interface_config} = get_config("interfaces")
    m = mod(get_mod(netman)) # wtf is this?
    context = get_context(netman)
    parse_and_start_config(context, interface_config, m)
  end

  @doc """
    Starts an interface
  """
  def start_interface(netman, interface, settings) do
    GenServer.call(netman, {:start, interface, settings}, :infinity)
  end

  @doc """
    Stops an interface
  """
  def stop_interface(netman, interface) do
    GenServer.call(netman, {:stop, interface}, :infinity)
  end

  @doc """
    Stops all interfaces
  """
  def stop_all(netman) do
    {:ok, interfaces} = get_config("interfaces")
    if interfaces do
      for {iface, _} <- interfaces do
        stop_interface(netman, iface)
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

  defp maybe_get_fpf(%Context{} = ctx) do
    # First Party Farmware is not really a network concern but here we are...
    {:ok, fpf} = GenServer.call(CS, {:get, Configuration, "first_party_farmware"})

    try do
      if fpf do
        Logger.info ">> is installing first party Farmwares."
        Farmbot.Farmware.Installer.enable_repo!(ctx, Farmbot.Farmware.Installer.Repository.Farmbot)
      end
      :ok
    rescue
      error ->
        Logger.warn(">> failed to install first party farmwares: #{inspect error}")
        debug_log "#{inspect System.stacktrace()}"
        :ok
    end
  end

  defp get_context(netman) when is_atom(netman) or is_pid(netman) do
    GenServer.call(netman, :get_context)
  end

  @doc """
  Checks for nxdomain. reboots if `nxdomain`.
  """
  def connection_test do
    Logger.info ">> doing connection test...", type: :busy
    case HTTPoison.get("http://neverssl.com/") do
      {:ok, _} ->
        Logger.info ">> connection test complete", type: :success
        :ok
      {:error, %HTTPoison.Error{id: nil, reason: :nxdomain}} ->
        Farmbot.System.reboot
      error ->
        Farmbot.System.factory_reset("Fatal Error during "
          <> "connection test! #{inspect error}")
    end
  end

  @doc """
    Connected to the World Wide Web. Should be called from the
    callback module.
  """
  def on_connect(context, pre_fun \\ nil, post_fun \\ nil)
  def on_connect(%Context{} = context, pre_fun, post_fun) do
    # Start the Downloader http client.
    Supervisor.start_child(Farmbot.System.Supervisor,
      Supervisor.Spec.worker(Downloader, [], [restart: :permanent]))

    # If we were supplied a pre connect callback, do that.
    if pre_fun, do: pre_fun.()

    :ok = connection_test()

    :ok = maybe_set_time()
    :ok = maybe_start_ssh()
    :ok = maybe_get_fpf(context)

    Logger.info ">> is trying to log in."
    {:ok, token} = Auth.try_log_in!(context.auth)

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

  @spec get_config(binary) :: {:ok, any}
  defp get_config(key), do: GenServer.call(CS, {:get, Network, key})
  # @spec get_config() :: {:ok, false | map}
  # defp get_config, do: GenServer.call(CS, {:get, Network, :all})

  defp get_mod(netman), do: GenServer.call(netman, :get_mod)

  # GENSERVER STUFF

  def handle_call(:get_context, _, state), do: {:reply, state.context, state}

  def handle_call(:get_mod, _, state), do: {:reply, state.target, state}
  def handle_call({:scan, interface_name}, _, state) do
     f = mod(state.target).scan(state.context, interface_name)
     {:reply, f, state}
  end

  def handle_call(:enumerate, _, state) do
    f = mod(state.target).enumerate(state.context)
    {:reply, f, state}
  end

  def handle_call({:start, interface, settings}, _, state) do
    f = mod(state.target).start_interface(state.context, interface, settings)
    {:reply, f, state}
  end

  def handle_call({:stop, interface}, _, state) do
    f = mod(state.target).stop_interface(state.context, interface)
    {:reply, f, state}
  end

  def terminate(reason, state) do
    ssh_pid = Process.whereis(SSH)
    if ssh_pid do
       SSH.stop(reason)
    end
    target_pid = Process.whereis(mod(state.target))
    if target_pid do
      GenServer.stop(target_pid, reason)
    end
  end

  # Behavior
  @type return_type :: :ok | {:error, term}
  @callback scan(Context.t, binary) :: [binary] | {:error, term}
  @callback enumerate(Context.t) :: [binary] | {:error, term}
  @callback start_interface(Context.t, binary, map) :: return_type
  @callback stop_interface(Context.t, binary) :: return_type
  @callback start_link(Context.t) :: {:ok, pid}
end
