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
    {:ok, config} = get_config("interfaces")
    config |> start_interfaces(event_manager)
    {:ok, %{manager: event_manager, handler: handler}}
  end

  @spec start_interfaces(map | nil, pid | atom) :: :ok | {:error, term}
  # We don't actually require network
  defp start_interfaces(nil, _), do: :ok
  defp start_interfaces(interfaces, event_manager) when is_map(interfaces) do
    for interface <- interfaces do
      # this will cause a runtime error if the interface can't be started.
      :ok = start_interface(interface, event_manager)
    end
    :ok
  end

  @spec start_interface({String.t, map} | false, pid | atom)
    :: :ok | {:error, term}
  defp start_interface(interface, event_manager)

  # this is where the interface actually gets started.
  # Start hostapd

  defp start_interface({_, %{"default" => false}}, _) do
    :ok
  end

  defp start_interface({iface,
    %{"type" => "wireless",
      "default" => "hostapd",
      "settings" => %{"ipv4_address" => ip_addr}}},
      event_manager)
  do
    {:ok, pid} =
      Hostapd.start_link(interface: iface,
        ip_address: ip_addr, manager: event_manager)
    :ok
  end

  defp start_interface({iface, %{
    "type" => "wireless",
    "default" => "dhcp",
    "settings" => settings
    }}, _event_manager)
  do
    key_mgmt = settings["key_mgmt"] |> String.to_atom
    ssid = settings["ssid"]
    psk = settings["psk"]
    case key_mgmt do
      :"WPA-PSK" ->
        {:ok, pid} = InterimWiFi.setup iface, [key_mgmt: key_mgmt, ssid: ssid, psk: psk]
      :NONE ->
        {:ok, pid} = InterimWiFi.setup iface, [key_mgmt: key_mgmt, ssid: ssid, psk: psk]
    end
    :ok
  end

  defp start_interface({iface, %{
    "type" => "wired",
    "default" => "dhcp",
    "settings" => _settings
    }}, _event_manager)
  do
    {:ok, pid} = InterimWiFi.setup iface, []
  end


  def handle_cast({:connected, iface, addr}, state) do
    {:ok, ntp} = get_config("ntp")
    {:ok, ssh} = get_config("ssh")
    if ntp, do: Ntp.set_time
    if ssh, do: Farmbot.Network.add_child(SSH)
    Farmbot.Auth.try_log_in
    {:noreply, state}
  end

  @doc """
    Starts the network manager. takes a target.
      Example:
        Iex()> Farmbot.Network.Manager.start_link("development")
               {:ok, pid}

        Iex()> Farmbot.Network.Manager.start_link("rpi3")
               {:ok, pid}
  """
  def start_link(ta), do: GenServer.start_link(__MODULE__, ta, name: __MODULE__)

  @spec get_iface(String.t) :: map | nil
  defp get_iface(iface) do
    {:ok, interfaces} = get_config("interfaces")
    interfaces[iface]
  end

  def handle_call(:state, _, state), do: {:reply, state, state}

  def handle_call({:scan, iface}, _, state) do
    config = get_iface(iface)
    if config do
      r = call_handler(state.manager, state.handler, {:scan, iface})
      {:reply, r, state}
    else
      {:reply, {:error, :no_interface}, state}
    end
  end

  def handle_call({:up, iface, _settings}, _, state) do
    config = get_iface(iface)
    if config do
      {:reply, config, state}
    else
      {:reply, {:error, :no_interface}, state}
    end
  end

  def handle_call({:down, iface}, _, state) do
    config = get_iface(iface)
    if config do
      {:reply, config, state}
    else
      {:reply, {:error, :no_interface}, state}
    end
  end

  def handle_call(:all_down, _, state) do
    r = do_all_down(state)
    {:reply, r, state}
  end

  def handle_call(:restart, _, state) do
    {:reply, {:error, :todo}, state}
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
    Logger.debug ">> is waiting for interfaces to come down."
    GenServer.stop(__MODULE__, :restart)
  end

  @doc """
    Sets an interface to connected with IP
  """
  @spec connected(String.t, String.t) :: no_return
  def connected(iface, addr) do
    GenServer.cast(__MODULE__, {:connected, iface, addr})
  end

  @doc """
    Call the accompanying network handler
  """
  @spec call_handler(pid | atom, pid | atom, term) :: any
  def call_handler(manager, handler, call) do
    GenEvent.call(manager, handler, call)
  end

  @spec get_config :: map | false
  defp get_config, do: GenServer.call(FBConfigStorage, {:get, Network, :all})

  @spec get_config(atom) :: any
  defp get_config(key),
    do: GenServer.call(FBConfigStorage, {:get, Network, key})

  # when this closes clean up everything
  def terminate(_reason,state) do
    Nerves.Firmware.reboot
    do_all_down(state)
  end

  defp do_all_down(state) do
    {:ok, config} = get_config
    interfaces = config["interfaces"]
    if interfaces do
      for interface <- interfaces do
         :ok = stop_interface(interface, state.manager)
      end
    end
  end

  defp stop_interface({_iface, %{"default" => false}}, _event_manager) do
    :ok
  end

  defp stop_interface({iface, %{"default" => "hostapd"}}, _) do
    mod_name = Module.concat([Hostapd, iface])
    GenServer.stop(mod_name)
    wait_for_hostapd(mod_name)
    :ok
  end

  defp stop_interface({iface, settings}, _event_manager) do
    Logger.debug ">> cant take down #{iface} with settings: #{inspect settings}"
  end

  defp wait_for_hostapd(mod_name) do
    f = Process.whereis(mod_name)
    if f do
      wait_for_hostapd(mod_name) # don't worry its safe
    end
  end
end
