defmodule Farmbot.Network.Manager do
  @moduledoc """
    Manages messages from a network event manager.
  """

  require Logger
  alias Farmbot.FileSystem.ConfigStorage, as: FBConfigStorage
  alias Nerves.InterimWiFi
  alias Farmbot.Network.Hostapd
  alias Farmbot.Network.Ntp
  alias Farmbot.Network.SSH
  use GenServer

  def init(target) do
    # this is the callback handler
    handler = Module.concat([Farmbot, Network, Handler, target])
    {:ok, event_manager} = handler.manager # Lookup or start GenEvent manager
    :ok = GenEvent.add_handler(event_manager, handler, [])
    :ok = call_handler(event_manager, handler, :ok)
    {:ok, []}
  end

  def handle_cast({:connected, iface, addr}, state) do
    {:ok, ntp} = get_config("ntp")
    {:ok, ssh} = get_config("ssh")
    if ntp, do: Ntp.set_time
    if ssh, do: Farmbot.Network.add_child(SSH)
    {:noreply, state}
  end

  @doc """
    Call the accompanying network handler
  """
  @spec call_handler(pid | atom, pid | atom, term) :: any
  def call_handler(manager, handler, call) do
    GenEvent.call(manager, handler, call)
  end

  def start_link(target) do
    GenServer.start_link(__MODULE__, target, name: __MODULE__)
  end

  # Someone populate this
  @type interim_wifi_settings :: []

  @doc """
    Gets the entire state. Will probably go away.
  """
  @spec get_state :: no_return # DELETEME
  def get_state, do: GenServer.call(__MODULE__, :state)

  @doc """
    Brings down every interface that has been brought up.
  """
  @spec all_down :: :ok | {:error, term}
  def all_down, do: GenServer.call(__MODULE__, :all_down)

  @doc """
    The pid of the manager that Network was started with.
  """
  @spec manager :: pid
  def manager, do: GenServer.call(__MODULE__, :manager)

  @doc """
    Bring an interface up with Nerves.InterimWiFi.
  """
  @spec up(String.t, interim_wifi_settings) :: :ok | {:error, term}
  def up(iface, settings),do: GenServer.call(__MODULE__, {:up, iface, settings})

  @doc """
    Bring an interface down.
  """
  @spec down(String.t) :: :ok | {:error, term}
  def down(iface), do: GenServer.call(__MODULE__, {:down, iface})


  @doc """
    Scans for wifi ssids.
  """
  @spec scan(String.t) :: [String.t] | {:error, term}
  def scan(iface), do: GenServer.call(__MODULE__, {:scan, iface})


  @doc """
    Restarts networking, reloading the config file.
  """
  @spec restart :: :ok | {:error, term}
  def restart do
    all_down
    # just to make sure everything is ready
    Logger.debug ">> is waiting for The web socket handler to die."
    Logger.debug ">> is waiting for interfaces to come down."
    GenServer.call(__MODULE__, :restart, :infinity)
  end

  @doc """
    Sets an interface to connected with IP
  """
  @spec connected(String.t, String.t) :: no_return
  def connected(iface, addr) do
    GenServer.cast(__MODULE__, {:connected, iface, addr})
  end

  @spec get_config :: map | false
  defp get_config, do: GenServer.call(FBConfigStorage, {:get, Network, :all})

  @spec get_config(atom) :: any
  defp get_config(key),
    do: GenServer.call(FBConfigStorage, {:get, Network, key})

  def terminate(_reason,_state) do end
end
