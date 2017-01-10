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
    Logger.debug ">> is starting networking"
    m = mod(target)
    {:ok, _cb} = m.start_link
    {:ok, interface_config} = get_config("interfaces")
    parse_and_start_config(interface_config, m)
    {:ok, target}
  end

  # if networking is disabled.
  defp parse_and_start_config(nil, _), do: :ok

  defp parse_and_start_config(config, m) do
    for {interface, settings} <- config do
        m.start_interface(interface, settings)
    end
  end

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
    Restarts networking services. This will block.
  """
  def restart() do
    stop_all()
    start_all()
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

  @doc """
    Starts all interfaces
  """
  def start_all do
    {:ok, interfaces} = get_config("interfaces")
    if interfaces do
      for {iface, settings} <- interfaces do
        start_interface(iface, settings)
      end
    end
  end

  @doc """
    Connected to the World Wide Web. Should be called from the
    callback module.
  """
  def on_connect(fun \\ nil) do
    # this happens because on wifi we try to do stuff before linux is
    # finished setting stuff up.
    Process.sleep(2000)
    Logger.debug ">> is connected to the World Wide Web"
    {:ok, ssh} = get_config("ssh")
    {:ok, ntp} = get_config("ntp")
    if ssh, do: SSH.start_link
    if ntp, do: Ntp.set_time
    if fun do
      spawn fun
    end
    Auth.try_log_in
  end

  @spec get_config(String.t) :: {:ok, any}
  @spec get_config() :: {:ok, false | map}
  defp get_config(key), do: GenServer.call(CS, {:get, Network, key})
  defp get_config, do: GenServer.call(CS, {:get, Network, :all})

  # GENSERVER STUFF
  def handle_call({:scan, interface_name}, _, target) do
     f = mod(target).scan(interface_name)
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
  @callback scan(String.t) :: [String.t]
  @callback start_interface(String.t, map) :: return_type
  @callback stop_interface(String.t) :: return_type
  @callback start_link :: {:ok, pid}
end
