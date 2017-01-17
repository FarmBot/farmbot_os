defmodule Farmbot.System.NervesCommon.Network do
  @doc """
    Common network functionality for Nerves Devices.
  """

  defmacro __using__(target: _target) do
    quote do
      @behaviour Farmbot.System.Network
      use GenServer
      require Logger
      alias Nerves.InterimWiFi, as: NervesWifi
      alias Farmbot.System.Network.Hostapd

      def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

      def init(_) do
        GenEvent.add_handler(event_manager(),
        Farmbot.System.NervesCommon.EventManager, [])
        {:ok, %{}}
      end

      # don't start this interface
      def start_interface(_interface, %{"default" => false}) do
        :ok
      end

      def start_interface(interface, %{"default" => "dhcp", "type" => "wired"} = s) do
        NervesWifi.setup(interface, []) |> cast_start_iface(interface, s)
      end

      def start_interface(interface,
        %{"default" => "dhcp",
          "type" => "wireless",
          "settings" => settings} = s)
      do
        ssid = settings["ssid"]
        case settings["key_mgmt"] do
          "NONE" ->
            NervesWifi.setup(interface, [ssid: ssid, key_mgmt: :NONE])
            |> cast_start_iface(interface, s)
          "WPA-PSK" ->
            psk = settings["psk"]
            NervesWifi.setup(interface,
              [ssid: ssid, key_mgmt: :"WPA-PSK", psk: psk])
            |> cast_start_iface(interface, s)
        end
        :ok
      end

      def start_interface(interface,
      %{"default" => "hostapd",
        "settings" => %{"ipv4_address" => ip_addr}, "type" => "wireless"} = s)
      do
        Hostapd.start_link([interface: interface, ip_address: ip_addr, manager: event_manager()])
        |> cast_start_iface(interface, s)
      end

      def cast_start_iface(blah, interface, settings) do
        case blah do
          {:ok, pid} ->
            GenServer.cast(__MODULE__, {:start_interface, interface, settings, pid})
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

      def stop_interface(interface) do
        GenServer.call(__MODULE__, {:stop_interface, interface})
      end

      def scan(iface) do
        case System.cmd("iw", [iface, "scan", "ap-force"]) do
          {res, 0} ->  res |> clean_ssid
          _ ->
          Logger.error ">> Could not scan on #{iface}. " <>
           "The device either isn't wireless or uses the legacy WEXT driver."
           []
        end
      end


      def enumerate, do: Nerves.NetworkInterface.interfaces -- ["lo"]

      defp event_manager, do: Nerves.NetworkInterface.event_manager()
      
      defp clean_ssid(hc) do
        hc
        |> String.replace("\t", "")
        |> String.replace("\\x00", "")
        |> String.split("\n")
        |> Enum.filter(fn(s) -> String.contains?(s, "SSID: ") end)
        |> Enum.map(fn(z) -> String.replace(z, "SSID: ", "") end)
        |> Enum.filter(fn(z) -> String.length(z) != 0 end)
      end

      # GENSERVER STUFF
      def handle_call({:stop_interface, interface}, _, state) do
        case state[interface] do
          {settings, pid} ->
            if settings["default"] == "hostapd" do
              GenServer.stop(pid, :stop_interface)
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
  end
end
