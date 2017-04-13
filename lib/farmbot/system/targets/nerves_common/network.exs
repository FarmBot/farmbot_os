defmodule Farmbot.System.NervesCommon.Network do
  @doc """
    Common network functionality for Nerves Devices.
  """

  defmacro __using__(target: _target, modules: modules) do
    quote do
      @behaviour Farmbot.System.Network
      use GenServer
      require Logger
      alias Nerves.InterimWiFi, as: NervesWifi
      alias Farmbot.System.Network.Hostapd

      def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

      def init(_) do
        for module <- unquote(modules) do
          {_, 0} = System.cmd("modprobe", [module])
        end
        # wait for a few seconds for everything to settle
        Process.sleep(5000)
        {:ok, %{logging_in: false}}
      end

      # don't start this interface
      def start_interface(_interface, %{"default" => false}) do
        :ok
      end

      def start_interface(interface, %{"default" => "dhcp", "type" => "wired"} = s) do
        interface |> NervesWifi.setup([]) |> cast_start_iface(interface, s)
      end

      def start_interface(interface,
        %{"default" => "dhcp",
          "type" => "wireless",
          "settings" => settings} = s)
      do
        ssid = settings["ssid"]
        case settings["key_mgmt"] do
          "NONE" ->
            interface
            |> NervesWifi.setup([ssid: ssid, key_mgmt: :NONE])
            |> cast_start_iface(interface, s)
          "WPA-PSK" ->
            psk = settings["psk"]
            interface
            |> NervesWifi.setup([ssid: ssid, key_mgmt: :"WPA-PSK", psk: psk])
            |> cast_start_iface(interface, s)
        end
        :ok
      end

      def start_interface(interface,
      %{"default" => "hostapd",
        "settings" => %{"ipv4_address" => ip_addr}, "type" => "wireless"} = s)
      do
        {:ok, manager} = GenEvent.start_link()
        [interface: interface, ip_address: ip_addr, manager: manager]
        |> Hostapd.start_link()
        |> cast_start_iface(interface, s)
      end

      def cast_start_iface(blah, interface, settings) do
        case blah do
          {:ok, pid} ->
            GenServer.cast(__MODULE__,
              {:start_interface, interface, settings, pid})
            :ok
          {:error, :already_added} ->
            :ok
          {:error, reason} ->
            Logger.error("Encountered an error starting " <>
              "#{interface}: #{reason}")
            {:error, reason}
          error ->
            Logger.error("Encountered an error starting " <>
              "#{interface}: #{error}")
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

      def handle_call(:logged_in, _from, state),
        do: {:reply, :ok, %{state | logging_in: false}}

      def handle_call({:stop_interface, interface}, _, state) do
        case state[interface] do
          {settings, pid} ->
            if settings["default"] == "hostapd" do
              GenServer.stop(pid, :normal)
              {:reply, :ok, Map.delete(state, interface)}
            else
              :ok = Registry.unregister(Nerves.NetworkInterface, interface)
              :ok = Registry.unregister(Nerves.Udhcpc, interface)
              :ok = Registry.unregister(Nerves.WpaSupplicant, interface)
              Logger.warn ">> cant stop: #{interface}"
              {:reply, {:error, :not_implemented}, state}
            end
          _ -> {:reply, {:error, :not_started}, state}
        end
      end

      def handle_cast({:start_interface, interface, settings, pid}, state) do
        {:ok, _} = Registry.register(Nerves.NetworkInterface, interface, [])
        {:ok, _} = Registry.register(Nerves.Udhcpc, interface, [])
        {:ok, _} = Registry.register(Nerves.WpaSupplicant, interface, [])
        {:noreply, Map.put(state, interface, {settings, pid})}
      end

      # ipv4_address: "192.168.29.241",
      # ipv4_broadcast: "192.168.29.255",
      # ipv4_gateway: "192.168.29.1",
      # ipv4_subnet_mask: "255.255.255.0"

      def handle_info({Nerves.Udhcpc, :bound, %{ifname: interface, ipv4_address: ip}}, state) do
        if state.logging_in do
          {:noreply, state}
        else
          that = self()
          spawn fn() ->
            Farmbot.System.Network.on_connect(fn() ->
              try do
                {_, 0} = System.cmd("epmd", ["-daemon"])
                :net_kernel.start(['farmbot@#{ip}'])
              rescue
                _ ->
                  Logger.warn "could not start epmd or something"
                  :ok
              end
              Logger.info ">> is waiting for linux and network and what not."
              Process.sleep(5000) # ye old race linux condidtion
              GenServer.call(that, :logged_in)
            end)
          end
          {:noreply, %{state | logging_in: true}}
        end
      end

      def handle_info({Nerves.WpaSupplicant, {:error, :psk, :FAIL}, %{ifname: iface}}, state) do
        Farmbot.System.factory_reset
        {:noreply, state}
      end

      def handle_info({Nerves.WpaSupplicant, event, %{ifname: iface}}, state) when is_atom(event) do
        event = event |> Atom.to_string
        wrong_key? = event |> String.contains?("reason=WRONG_KEY")
        not_found? = event |> String.contains?("CTRL-EVENT-NETWORK-NOT-FOUND")
        if wrong_key?, do: Farmbot.System.factory_reset
        if not_found?, do: Farmbot.System.factory_reset
        {:noreply, state}
      end

      def handle_info(info, state) do
        {:noreply, state}
      end

      def terminate(_,_state) do
        # TODO STOP INTERFACES
        :ok
      end

    end
  end
end
