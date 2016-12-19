defmodule Farmbot.Network do
  # TODO MAKE THIS CONNECT TO THE WEB SOCKET IN CONFIGURATOR
  @moduledoc """
    Manages messages from a network event manager.
  """
  require Logger
  alias Farmbot.FileSystem.ConfigStorage, as: FBConfigStorage

  defmodule Interface, do: defstruct [:ipv4_address, :pid]
  defmodule State do
    defstruct [connected?: false, interfaces: %{}]
    @type t :: %__MODULE__{connected?: boolean, interfaces: %{}}
  end

  #Nerves.InterimWiFi.setup "wlan0", ssid: ssid, key_mgmt: :"WPA-PSK", psk: pass
  #Nerves.InterimWiFi.setup "eth0"

  def start_link(hardware) do
    GenServer.start_link(__MODULE__, hardware, name: __MODULE__)
  end

  def init(hardware) do
    Process.flag :trap_exit, true
    Logger.debug ">> is starting epmd."
    System.cmd("epmd", ["-daemon"])
    Logger.debug ">> is initializing networking on: #{inspect hardware}"
    # this is from the json file yet to be defined.
    {:ok, config} = get_config
    # The module of the handler.
    handler = Module.concat([Farmbot,Network,Handler,hardware])
    # start (or forward) an event manager
    {:ok, manager} = handler.manager
    # add the handler. (probably change this to a mon handler)
    GenEvent.add_handler(manager, handler, {self(), config})

    blah = parse_config(config, hardware)
    {:ok, %State{blah | connected?: false}}
  end

  def handle_cast({:connected, interface, ip}, state) do
    Logger.debug ">>'s #{interface} is connected: #{ip}"
    case Map.get(state.interfaces, interface) do
      %Interface{} = thing ->
        new_interface = %Interface{thing | ipv4_address: ip}
        new_state =
          %State{state | connected?: true, interfaces: Map.put(state.interfaces, interface, new_interface)}
        {:noreply, new_state}
      t ->
        Logger.warn(
          ">> encountered something weird updating #{interface} state: #{inspect t}")
        {:noreply, %State{state | connected?: true }}
    end
  end

  def handle_info({:EXIT, pid, reason}, state) do
    Logger.debug "something died: #{inspect pid}, #{inspect reason}"
    {:noreply, state}

  end

  def handle_call(:state, _, state), do: {:reply, state, state}

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def terminate(_,_), do: :ok

  defp get_config do
    GenServer.call(FBConfigStorage, {:get, __MODULE__, :all})
  end

  # Be very careful down here
  defp parse_config(nil, _), do: %State{interfaces: %{}}
  defp parse_config(config, hardware) do
    # {"wlan0", %{"type" => "hostapd"}}
    # {"eth0", %{"type" => "ethernet", "ip" => %{"mode" => "dhcp"}}}
    # {"wlan0",
    #    %{"type" => "wifi",
    #      "ip" =>
    #          %{"mode" => "dhcp"},
    #            "wifi" =>
    #                %{"ssid" =>"example",
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
    %State{interfaces: something}
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
