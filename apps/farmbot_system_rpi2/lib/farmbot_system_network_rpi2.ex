defmodule Module.concat([Farmbot, System, "rpi2", Network]) do
  @moduledoc false
  @behaviour Farmbot.System.Network
  use GenServer
  require Logger
  alias Nerves.InterimWiFi, as: NervesWifi
  alias Farmbot.System.Network.Hostapd

  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    GenEvent.add_handler(event_manager(),
    Module.concat([Farmbot, System, "rpi3", Network, EventManager]), [])
    {:ok, %{}}
  end

  # don't start this interface
  def start_interface(_interface, %{"default" => false}) do
    :ok
  end

  def start_interface(interface, %{"default" => "dhcp", "type" => "wired"} = s) do
    case NervesWifi.setup(interface, []) do
      {:ok, pid} ->
        GenServer.cast(__MODULE__, {:start_interface, interface, s, pid})
        :ok
      {:error, :already_added} ->
        :ok
      {:error, reason} ->
        Logger.error("Encountered an error starting #{interface}: #{reason}")
        {:error, reason}
      error ->
        Logger.error("Encountered an error starting #{interface}: #{error}")
        {:error, error}
    end
  end

  def start_interface(interface,
    %{"default" => "dhcp",
      "type" => "wireless",
      "settings" => settings} = s)
  do
    ssid = settings["ssid"]
    case settings["key_mgmt"] do
      "NONE" ->
        {:ok, pid} = NervesWifi.setup(interface, [ssid: ssid, key_mgmt: :NONE])
        GenServer.cast(__MODULE__, {:start_interface, interface, s, pid})
      "WPA-PSK" ->
        psk = settings["psk"]
        {:ok, pid}  = NervesWifi.setup(interface,
          [ssid: ssid, key_mgmt: :"WPA-PSK", psk: psk])
          GenServer.cast(__MODULE__, {:start_interface, interface, s, pid})
    end
    :ok
  end

  def start_interface(interface,
  %{"default" => "hostapd",
    "settings" => %{"ipv4_address" => ip_addr}, "type" => "wireless"} = s)
  do
    {:ok, pid} = Hostapd.start_link([interface: interface, ip_address: ip_addr, manager: event_manager()])
    GenServer.cast(__MODULE__, {:start_interface, interface, s, pid})
    :ok
  end

  def stop_interface(interface) do
    GenServer.call(__MODULE__, {:stop_interface, interface})
  end

  def scan(iface) do
    {hc, 0} = System.cmd("iw", [iface, "scan", "ap-force"])
    hc |> clean_ssid
  end

  defp event_manager, do: Nerves.NetworkInterface.event_manager()
  defp clean_ssid(hc) do
    hc
    |> String.replace("\t", "")
    |> String.replace("\\x00", "")
    |> String.split("\n")
    |> Enum.filter(fn(s) -> String.contains?(s, "SSID") end)
    |> Enum.map(fn(z) -> String.replace(z, "SSID: ", "") end)
    |> Enum.filter(fn(z) -> String.length(z) != 0 end)
  end

  # GENSERVER STUFF
  def handle_call({:stop_interface, interface}, _, state) do
    case state[interface] do
      {settings, pid} ->
        if settings["default"] == "hostapd" do
          GenServer.stop(pid, :uhhh)
          {:reply, :ok, Map.delete(state, interface)}
        else
          Logger.warn ">> cant stop: #{interface}"
          {:reply, {:error, :not_implemented}, state}
        end
      _ -> {:reply, {:error, :not_started}, state}
    end
  end

  def handle_cast({:start_interface, interface, settings, pid}, state) do
    {:noreply, Map.put(state, interface, {settings, pid})}
  end

  def terminate(_,_state) do
    # TODO STOP INTERFACES
    :ok
  end
end
