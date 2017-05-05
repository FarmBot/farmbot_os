defmodule Farmbot.System.NervesCommon.Network do
  @doc """
    Common network functionality for Nerves Devices.
  """

  defmacro __using__(opts) do
    modules = Keyword.get(opts, :modules, [])
    callback = Keyword.get(opts, :callback)
    target = Keyword.get(opts, :target)
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

        # execute a callback if supplied.
        cb = unquote(callback)
        if cb do
          Logger.info ">> doing target specific setup: #{unquote(target)}"
          cb.()
        end

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

      def scan(iface), do: do_scan(iface)

      def do_scan(iface, retry \\ false)

      def do_scan(iface, true) do
        {:ok, _} = NervesWifi.setup(iface)
        Process.sleep(1000)
        results =
          case do_iw_scan(iface) do
            {:ok, f} -> f
            {:error, _} ->
              Logger.error ">> Could not scan on #{iface}. " <>
               "The device either isn't wireless or uses the legacy WEXT driver."
              []
          end
        NervesWifi.teardown(iface)
        results
      end

      def do_scan(iface, false) do
        case do_iw_scan(iface) do
          {:ok, results} -> results
          {:error, _} -> do_scan(iface, true)
        end
      end

      defp do_iw_scan(iface) do
        case System.cmd("iw", [iface, "scan", "ap-force"]) do
          {res, 0} ->
            f = res |> clean_ssid
            {:ok, f}
          e -> {:error, e}
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

      def handle_call(:logged_in, _from, state) do
        # Tear down hostapd here
        {:reply, :ok, %{state | logging_in: false}}
      end

      def handle_call({:stop_interface, interface}, _, state) do
        case state[interface] do
          {settings, pid} ->
            if settings["default"] == "hostapd" do
              if Process.alive?(pid) do
                GenServer.stop(pid, :normal)
              end
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
                  Logger.warn "could not start epmd or net_kernel"
                  :ok
              end
              Logger.info ">> is waiting for linux and network and what not."
              Process.sleep(5000) # ye old race linux condidtion
              GenServer.call(that, :logged_in)
            end,
            fn(token) ->
               for {key, value} <- state do
                 if match?({%{"default" => "hostapd"}, _}, value) do
                   Logger.info "Killing #{key}"
                   stop_interface(key)
                 end
               end
            end)

          end
          {:noreply, %{state | logging_in: true}}
        end
      end

      def handle_info({Nerves.WpaSupplicant, {:error, :psk, :FAIL}, %{ifname: iface}}, state) do
        Farmbot.System.factory_reset("""
        I could not authenticate with the access point. This could be a bad
        password, or an unsupported network type.
        """)
        {:noreply, state}
      end

      def handle_info({Nerves.WpaSupplicant, event, %{ifname: iface}}, state) when is_atom(event) do
        event = event |> Atom.to_string
        wrong_key? = event |> String.contains?("reason=WRONG_KEY")
        not_found? = event |> String.contains?("CTRL-EVENT-NETWORK-NOT-FOUND")
        if wrong_key?, do: Farmbot.System.factory_reset("""
        I could not authenticate with the access point. This could be a bad
        password, or an unsupported network type.
        """)

        if not_found?, do: Farmbot.System.factory_reset("""
        I could not find the wifi access point. Check that it was inputted correctly.
        """)

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
