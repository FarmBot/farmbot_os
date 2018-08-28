### WARNING(Connor) 2018-08-16
### Do not touch anything in this file unless you understand _exactly_
### what you are doing. If you look at it wrong, you will cause the
### Raspberry pi to kernel panic for some reason. I have
### no idea why. Just move along.
### If you are in this file, please at least be kind enough as to not touch any
### of the timing sensitive things. It _will_ break.

defmodule Farmbot.Target.Network.Manager do
  use GenServer
  use Farmbot.Logger
  import Farmbot.System.ConfigStorage, only: [get_config_value: 3]
  alias Farmbot.Target.Network.NotFoundTimer
  import Farmbot.Target.Network, only: [test_dns: 0]

  def debug_logs? do
    Application.get_env(:farmbot, :network_debug_logs, false)
  end

  def debug_logs(bool) do
    Application.put_env(:farmbot, :network_debug_logs, bool)
  end

  def get_ip_addr(interface) do
    GenServer.call(:"#{__MODULE__}-#{interface}", :ip)
  end

  def get_state(interface) do
    :sys.get_state(:"#{__MODULE__}-#{interface}")
  end

  def start_link(interface, opts) do
    GenServer.start_link(__MODULE__, {interface, opts}, [name: :"#{__MODULE__}-#{interface}"])
  end

  def init({interface, opts} = args) do
    Logger.busy(3, "Waiting for interface #{interface} up.")

    unless interface in Nerves.NetworkInterface.interfaces() do
      Process.sleep(1000)
      init(args)
    end

    Logger.success(3, "Interface #{interface} is up.")
    s1 = get_config_value(:string, "settings", "default_ntp_server_1")
    s2 = get_config_value(:string, "settings", "default_ntp_server_2")
    Nerves.Time.set_ntp_servers([s1, s2])
    maybe_hack_tzdata()

    settings = Enum.map(opts, fn({key, value}) ->
      case key do
        :key_mgmt -> {key, String.to_atom(value)}
        _ -> {key, value}
      end
    end)
    Nerves.Network.IFSupervisor.setup(interface, settings)

    {:ok, _} = Elixir.Registry.register(Nerves.NetworkInterface, interface, [])
    {:ok, _} = Elixir.Registry.register(Nerves.Udhcpc, interface, [])
    {:ok, _} = Elixir.Registry.register(Nerves.WpaSupplicant, interface, [])

    domain = node() |> to_string() |> String.split("@") |> List.last() |> Kernel.<>(".local")
    init_mdns(domain)
    state = %{
      # These won't change
      mdns_domain: domain,
      interface: interface,
      opts: settings,

      # These change based on
      # Events from timers and other processes.
      ip_address: nil,
      connected: false,
      ap_connected: false,

      # Tries to reconnect after "network not found" event.
      reconnect_timer: nil,

      # Tests internet connectivity.
      dns_timer: nil,
    }
    {:ok, state}
  end

  def terminate(_, state) do
    # This hopefully makes the NetworkInterface ready when this
    # GenServer is restarted.
    Nerves.Network.IFSupervisor.teardown(state.interface)
    Nerves.NetworkInterface.ifdown(state.interface)
    Process.sleep(5000)
    Nerves.NetworkInterface.ifup(state.interface)
    Process.sleep(5000)
  end

  def handle_call(:ip, _, state) do
    {:reply, state.ip_address, state}
  end

  # When assigned an IP address.
  def handle_info({Nerves.Udhcpc, :bound, %{ipv4_address: ip}}, state) do
    Logger.debug 3, "Ip address: #{ip}"
    NotFoundTimer.stop()
    connected = match?({:ok, {:hostent, _, _, :inet, 4, _}}, test_dns())
    if connected do
      init_mdns(state.mdns_domain)
      dns_timer = restart_dns_timer(state.dns_timer, 45_000)
      update_mdns(ip, state.mdns_domain)
      {:noreply, %{state | dns_timer: dns_timer, ip_address: ip, connected: true}}
    else
      {:noreply, %{state | connected: false, ip_address: ip}}
    end
  end

  def handle_info({Nerves.WpaSupplicant, {:INFO, "WPA: 4-Way Handshake failed - pre-shared key may be incorrect"}, _}, state) do
    Logger.error 1, "Incorrect PSK."
    Farmbot.System.factory_reset("WIFI Authentication failed. (incorrect psk)")
    {:stop, :normal, state}
  end

  def handle_info({Nerves.WpaSupplicant, :"CTRL-EVENT-NETWORK-NOT-FOUND", _}, state) do
    # stored in minutes
    reconnect_timer = if state.connected, do: restart_connection_timer(state)
    maybe_refresh_token()
    NotFoundTimer.start()
    new_state = %{state |
      ap_connected: false,
      connected: false,
      ip_address: nil,
      reconnect_timer: reconnect_timer
    }
    {:noreply, new_state}
  end

  def handle_info({Nerves.WpaSupplicant, :"CTRL-EVENT-CONNECTED", _}, state) do
    # Don't update `connected`. This is not a real test of connectivity.
    Logger.success 1, "Connected to access point."
    NotFoundTimer.stop()
    {:noreply, %{state | ap_connected: true}}
  end

  def handle_info({Nerves.WpaSupplicant, :"CTRL-EVENT-DISCONNECTED", _}, state) do
    # stored in minutes
    reconnect_timer = if state.connected, do: restart_connection_timer(state)
    maybe_refresh_token()
    NotFoundTimer.start()
    new_state = %{state |
      ap_connected: false,
      connected: false,
      ip_address: nil,
      reconnect_timer: reconnect_timer
    }
    {:noreply, new_state}
  end

  def handle_info({Nerves.WpaSupplicant, info, infoa}, state) do
    # :"CTRL-EVENT-SSID-TEMP-DISABLED id=0 ssid=\"Rory's Phone\" auth_failures=2 duration=20 reason=CONN_FAILED"
    case is_atom(info) && to_string(info) do
      <<"CTRL-EVENT-SSID-TEMP-DISABLED" <> _>> = msg ->
        if String.contains?(msg, "duration=20") do
          reconnect_timer = if state.connected, do: restart_connection_timer(state)
          maybe_refresh_token()
          NotFoundTimer.start()
          new_state = %{state |
            ap_connected: false,
            connected: false,
            ip_address: nil,
            reconnect_timer: reconnect_timer
          }
          {:noreply, new_state}
        else
          {:noreply, state}
        end
      _ ->
        if debug_logs?() do
          IO.inspect {info, infoa}, label: "unhandled wpa event"
        end
        {:noreply, state}
    end
  end

  def handle_info(:reconnect_timer, %{ap_connected: false} = state) do
    Logger.warn 1, "Wireless network not found still. Trying again."
    {:stop, :reconnect_timer, state}
  end

  def handle_info(:reconnect_timer, %{ap_connected: true} = state) do
    Logger.success 1, "Wireless network reconnected."
    {:noreply, state}
  end

  def handle_info(:dns_timer, %{connected: true} = state) do
    case test_dns() do
      {:ok, {:hostent, _host_name, _aliases, :inet, 4, _}} ->
        # Farmbot is still connected. NBD
        {:noreply, %{state | dns_timer: restart_dns_timer(nil, 45_000)}}

      {:error, err} ->
        maybe_refresh_token()
        Logger.warn 3, "Farmbot was disconnected from the internet: #{inspect err}"
        {:noreply, %{state | connected: false, dns_timer: restart_dns_timer(nil, 20_000)}}
    end
  end

  def handle_info(:dns_timer, %{ip_address: nil} = state) do
    Logger.warn 3, "Farmbot still disconnected from the internet"
    {:noreply, %{state | connected: false, dns_timer: restart_dns_timer(nil, 20_000)}}
  end

  def handle_info(:dns_timer, state) do
    case test_dns() do
      {:ok, {:hostent, _host_name, aliases, :inet, 4, _}} ->
        # If we weren't previously connected, send a log.
        Logger.success 3, "Farmbot was reconnected to the internet: #{inspect aliases}"
        maybe_refresh_token()
        new_state = %{state |
          connected: true,
          dns_timer: restart_dns_timer(nil, 45_000),
        }
        {:noreply, new_state}

      {:error, err} ->
        Logger.warn 3, "Farmbot was disconnected from the internet: #{inspect err}"
        maybe_refresh_token()
        {:noreply, %{state | connected: false, dns_timer: restart_dns_timer(nil, 20_000)}}
    end
  end

  def handle_info(_event, state) do
    # Logger.warn 3, "unhandled network event: #{inspect event}"
    {:noreply, state}
  end

  defp cancel_timer(timer) do
    # If there was a timer, cancel it.
    if timer do
      # Logger.warn 3, "Cancelling Network timer"
      Process.cancel_timer(timer)
    end
    nil
  end

  defp restart_dns_timer(timer, time) when is_integer(time) do
    cancel_timer(timer)
    Process.send_after(self(), :dns_timer, time)
  end

  defp restart_connection_timer(state) do
    # TODO(Connor) - 2018-08-15 There is a bug in Nerves.Network
    # Where `Nerves.Network.teardown(ifname)` doesn't actually do anything.
    cancel_timer(state.reconnect_timer)
    Nerves.Network.IFSupervisor.teardown(state.interface)
    Nerves.NetworkInterface.ifdown(state.interface)
    Process.sleep(5000)
    Nerves.NetworkInterface.ifup(state.interface)
    Process.sleep(5000)
    Nerves.Network.setup(state.interface, state.opts)
    Process.send_after(self(), :reconnect_timer, 30_000)
  end

  defp maybe_refresh_token do
    if Process.whereis(Farmbot.Bootstrap.AuthTask) do
      Farmbot.Bootstrap.AuthTask.force_refresh()
    else
      Logger.warn 1, "AuthTask not running yet"
    end
  end

  defp init_mdns(mdns_domain) do
    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: mdns_domain,
      data: :ip,
      ttl: 120,
      type: :a
    })
  end

  defp update_mdns(ip, _mdns_domain) do
    ip_tuple = to_ip_tuple(ip)
    Mdns.Server.stop()

    # Give the interface time to settle to fix an issue where mDNS's multicast
    # membership is not registered. This occurs on wireless interfaces and
    # needs to be revisited.
    :timer.sleep(100)

    Mdns.Server.start(interface: ip_tuple)
    Mdns.Server.set_ip(ip_tuple)
  end

  defp to_ip_tuple(str) do
    str
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  @fb_data_dir Application.get_env(:farmbot, :data_path)
  @tzdata_dir Application.app_dir(:tzdata, "priv")
  def maybe_hack_tzdata do
    case Tzdata.Util.data_dir() do
      @fb_data_dir -> :ok
      _ ->
        Logger.debug 3, "Hacking tzdata."
        objs_to_cp = Path.wildcard(Path.join(@tzdata_dir, "*"))
        for obj <- objs_to_cp do
          File.cp_r obj, @fb_data_dir
        end
        Application.put_env(:tzdata, :data_dir, @fb_data_dir)
        :ok
    end
  end
end
