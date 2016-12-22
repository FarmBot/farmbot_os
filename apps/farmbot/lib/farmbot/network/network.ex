defmodule Farmbot.Network do
  # TODO MAKE THIS CONNECT TO THE WEB SOCKET IN CONFIGURATOR
  @moduledoc """
    Manages messages from a network event manager.
  """
  require Logger
  alias Farmbot.FileSystem.ConfigStorage, as: FBConfigStorage
  alias Farmbot.Configurator.EventManager, as: EM
  alias Farmbot.Network.ConfigSocket, as: SocketHandler

  defmodule Interface, do: defstruct [:ipv4_address, :pid]
  defmodule State do
    @enforce_keys [:manager, :hardware]
    defstruct [connected?: false, interfaces: %{}, manager: nil, hardware: nil]
    @type t :: %__MODULE__{connected?: boolean, interfaces: %{}, manager: pid}
  end

  #Nerves.InterimWiFi.setup "wlan0", ssid: ssid, key_mgmt: :"WPA-PSK", psk: pass
  #Nerves.InterimWiFi.setup "eth0"

  def start_link(hardware) do
    GenServer.start_link(__MODULE__, hardware, name: __MODULE__)
  end

  def init(hardware) do
    Logger.debug ">> is initializing networking on: #{inspect hardware}"
    Process.flag :trap_exit, true
    # i guess this can be here.
    GenEvent.add_handler(EM, SocketHandler, [])

    # Logger.debug ">> is starting epmd."
    # System.cmd("epmd", ["-daemon"])
    # this is from the json file yet to be defined.
    {:ok, config} = get_config
    # The module of the handler.
    handler = Module.concat([Farmbot,Network,Handler,hardware])
    # start (or forward) an event manager
    {:ok, manager} = handler.manager
    # add the handler. (probably change this to a mon handler)
    GenEvent.add_handler(manager, handler, {self(), config})

    {:ok, %State{connected?: false,
              manager: manager,
              hardware: hardware,
              interfaces: parse_config(config, hardware)}}
  end

  def handle_cast({:connected, interface, ip}, state) do
    Logger.debug ">>'s #{interface} is connected: #{ip}"
    # I don't want either of these here.
    GenServer.cast(Farmbot.BotState.Authorization, :try_log_in)
    Farmbot.BotState.set_time

    case Map.get(state.interfaces, interface) do
      %Interface{} = thing ->
        new_interface = %Interface{thing | ipv4_address: ip}
        new_state =
          %State{state | connected?: true,
            interfaces: Map.put(state.interfaces, interface, new_interface)}
        {:noreply, new_state}
      t ->
        Logger.warn(
          ">> encountered something weird updating #{interface} "
          <> "state: #{inspect t}")
        {:noreply, %State{state | connected?: true }}
    end
  end

  def handle_info({:EXIT, pid, reason}, state) do
    Logger.debug "something in network died: #{inspect pid}, #{inspect reason}"
    {:noreply, state}
  end
  def handle_info(_, state), do: {:noreply, state}

  def handle_call(:all_down, _, state) do
    Enum.each(state.interfaces, fn({interface, config}) ->
      Logger.debug ">> is stoping #{interface}"
      if is_pid(config.pid) do
        Process.exit(config.pid, :down)
      end
    end)
    Logger.debug ">> has stopped all network interfaces."
    {:reply, :ok, %State{state | connected?: false, interfaces: %{}}}
  end

  def handle_call({:up, _iface, [host: true]}, _, state) do
    {:reply, :todo, state}
  end

  def handle_call({:up, iface, settings }, _, state) do
    {:ok, pid} = Nerves.InterimWiFi.setup(iface, settings)
    new_interface = %Interface{pid: pid}
    {:reply, pid, %State{state |
      interfaces: Map.put(state.interfaces, iface, new_interface)}}
  end

  def handle_call({:down, iface}, _, state) do
    iface = state.interfaces[iface]
    if iface do
      Process.exit(iface.pid, :down)
      {:reply, :ok, %State{state |
        interfaces: Map.delete(state.interfaces, iface)}}
    else
      Logger.debug ">> could not bring down #{iface}."
      {:reply, :no_iface, state}
    end
  end

  def handle_call(:restart, _, state) do
    if Enum.empty?(state.interfaces) do
      {:ok, new_state} = init(state.hardware)
      {:reply, :ok, new_state}
    else
      Logger.debug ">> detected there are still some network interfaces up."
      {:reply, {:error, :not_down}, state}
    end
  end
  def handle_call(:manager, _, state), do: {:reply, state.manager, state}
  def handle_call(:state, _, state), do: {:reply, state, state}
  @doc """
    Gets the entire state. Will probably go away.
  """
  def state, do: GenServer.call(__MODULE__, :state)
  @doc """
    Brings down every interface that has been brought up.
  """
  def all_down, do: GenServer.call(__MODULE__, :all_down)
  @doc """
    The pid of the manager that Network was started with.
  """
  def manager, do: GenServer.call(__MODULE__, :manager)
  @doc """
    Bring an interface up with Nerves.InterimWiFi.
  """
  def up(iface, settings),do: GenServer.call(__MODULE__, {:up, iface, settings})
  @doc """
    Bring an interface down.
  """
  def down(iface), do: GenServer.call(__MODULE__, {:down, iface})

  @doc """
    Restarts networking, reloading the config file.
  """
  def restart do
    all_down
    # just to make sure everything is ready
    Logger.debug ">> is waiting for The web socket handler to die."
    GenEvent.remove_handler(EM, SocketHandler, [])
    Logger.debug ">> is waiting for interfaces to come down."
    Process.sleep 5000
    GenServer.call(__MODULE__, :restart, :infinity)
  end

  def terminate(_reason,_state) do
    GenEvent.remove_handler(EM, SocketHandler, [])
  end

  defp get_config, do: GenServer.call(FBConfigStorage, {:get, __MODULE__, :all})

  # Be very careful down here
  defp parse_config(false, _),
    do: %State{interfaces: %{}, manager: self, hardware: "development"}
  defp parse_config(config, hardware) do
    # {"wlan0", %{"type" => "hostapd"}}
    # {"eth0", %{"type" => "ethernet", "ip" => %{"mode" => "dhcp"}}}
    # {"wlan0",
    #    %{"type" => "wifi",
    #      "ip" => %{"mode" => "dhcp"},
    #      "wifi" => %{"ssid" =>"example",
    #                  "psk" => "example_pass",
    #                  "key_mgmt" => "WPA-PSK"}}}
    something = Map.new(config, fn({interface, settings}) ->
      case Map.get(settings, "type") do
        "hostapd" ->
          # start hostapd on this interface
          ip = "192.168.24.1"
          Logger.debug ">> is starting hostapd client"
          handler = Module.concat([Farmbot,Network,Handler,hardware])
          {:ok, manager} = handler.manager
          {:ok, pid} =
            Farmbot.Network.Hostapd.start_link(
            [interface: interface, ip_address: ip, manager: manager])
          {interface, %Interface{ipv4_address: ip, pid: pid}}
        "ethernet" ->
          Logger.debug ">> is starting ethernet client"
          interface_settings = parse_ethernet_settings(settings)
          {:ok, pid} = Nerves.InterimWiFi.setup(interface, interface_settings)
          {interface, %Interface{pid: pid}}
        "wifi" ->
          Logger.debug ">> is starting wpa_supplicant client"
          interface_settings = parse_wifi_settings(settings)
          {:ok, pid} = Nerves.InterimWiFi.setup(interface, interface_settings)
          {interface, %Interface{pid: pid}}
      end
    end)
    something
  end

  defp parse_ip_settings(ip_settings) do
    case Map.get(ip_settings, "mode") do
      "dhcp" -> [ipv4_address_method: "dhcp"]
      "static" ->
        s = Map.get(ip_settings, "settings")
        parse_static_ip_settings(s)
    end
  end

  defp parse_static_ip_settings(s) do
    Enum.reduce(s, [ipv4_address_method: "static"], fn({k,v}, acc) ->
      case k do
        "ipv4_address" -> acc ++ [ipv4_address: v]
        "ipv4_subnet_mask" -> acc ++ [ipv4_subnet_mask: v]
        "name_servers" -> acc ++ [name_servers: v]
        _ -> acc ++ []
      end
    end)
  end

  defp parse_ethernet_settings(settings) do
    # %{"type" => "ethernet", "settings" => %{"ip" => %{"mode" => "dhcp"}} }
    ip_settings =
      settings
      |> Map.get("settings")
      |> Map.get("ip")
      |> parse_ip_settings
    ip_settings
  end

  defp parse_wifi_settings(settings) do
    ip_settings =
      settings
      |> Map.get("settings")
      |> Map.get("ip")
      |> parse_ip_settings

    wifi_settings =
      settings
      |> Map.get("settings")
      |> Map.get("wifi")
      |> parse_more_wifi_settings
    ip_settings ++ wifi_settings
  end

  defp parse_more_wifi_settings(s) do
    case Map.get(s, "key_mgmt") do
      "NONE" -> [key_mgmt: :NONE]
      "WPA-PSK" ->
        [key_mgmt: :"WPA-PSK", psk: Map.get(s, "psk"), ssid: Map.get(s, "ssid")]
      _ -> raise "unsupported key management"
    end
  end
end
