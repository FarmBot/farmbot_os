defmodule Farmbot.Target.Network.Manager do
  use GenServer
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage
  alias Nerves.Network
  alias Farmbot.Target.Network.Ntp
  import Farmbot.Target.Network, only: [test_dns: 0]

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

    {:ok, _} = Elixir.Registry.register(Nerves.NetworkInterface, interface, [])
    {:ok, _} = Elixir.Registry.register(Nerves.Udhcpc, interface, [])
    {:ok, _} = Elixir.Registry.register(Nerves.WpaSupplicant, interface, [])
    settings = Enum.map(opts, fn({key, value}) ->
      case key do
        :key_mgmt -> {key, String.to_atom(value)}
        _ -> {key, value}
      end
    end)
    Network.setup(interface, settings)
    domain = node() |> to_string() |> String.split("@") |> List.last() |> Kernel.<>(".local")
    init_mdns(domain)
    {:ok, %{mdns_domain: domain, interface: interface, opts: settings, ip_address: nil, connected: false, not_found_timer: nil, ntp_timer: nil, dns_timer: nil}}
  end

  def handle_call(:ip, _, state) do
    {:reply, state.ip_address, state}
  end

  def handle_info({Nerves.Udhcpc, :bound, %{ipv4_address: ip}}, state) do
    Logger.debug 3, "Ip address: #{ip}"
    connected = match?({:ok, {:hostent, _, _, :inet, 4, _}}, test_dns())
    if connected do
      init_mdns(state.mdns_domain)
      ntp_timer = restart_ntp_timer(state.ntp_timer)
      not_found_timer = cancel_timer(state.not_found_timer)
      dns_timer = restart_dns_timer(state.dns_timer, 45_000)
      update_mdns(ip, state.mdns_domain)
      {:noreply, %{state | dns_timer: dns_timer, ip_address: ip, connected: true, not_found_timer: not_found_timer, ntp_timer: ntp_timer}}
    else
      {:noreply, %{state | connected: false, ntp_timer: nil, ip_address: ip}}
    end
  end

  def handle_info({Nerves.WpaSupplicant, {:INFO, "WPA: 4-Way Handshake failed - pre-shared key may be incorrect"}, _}, state) do
    Logger.error 1, "Incorrect PSK."
    Farmbot.System.factory_reset("WIFI Authentication failed. (incorrect psk)")
    {:stop, :normal, state}
  end

  def handle_info({Nerves.WpaSupplicant, :"CTRL-EVENT-NETWORK-NOT-FOUND", _}, %{not_found_timer: nil} = state) do
    # stored in minutes
    delay_timer = (ConfigStorage.get_config_value(:float, "settings", "network_not_found_timer") || 1) * 60_000
    timer = Process.send_after(self(), :network_not_found_timer, round(delay_timer))
    {:noreply, %{state | not_found_timer: timer, connected: false}}
  end

  def handle_info({Nerves.WpaSupplicant, :"CTRL-EVENT-DISCONNECTED", _}, state) do
    Logger.error 1, "Disconnected from WiFi!"
    {:noreply, %{state | connected: false}}
  end

  def handle_info({Nerves.WpaSupplicant, _, _}, state) do
    # Logger.error 1 "unhandled wpa event: {#{inspect info}, #{inspect infoa}}"
    {:noreply, state}
  end

  def handle_info(:network_not_found_timer, state) do
    delay_minutes = (ConfigStorage.get_config_value(:float, "settings", "network_not_found_timer") || 1)
    disable_factory_reset? = ConfigStorage.get_config_value(:bool, "settings", "disable_factory_reset")
    first_boot? = ConfigStorage.get_config_value(:bool, "settings", "first_boot")
    connected? = state.connected
    cond do
      connected? ->
        Logger.warn 1, "Not resetting because network is connected."
        {:noreply, %{state | not_found_timer: nil}}
      disable_factory_reset? ->
        Logger.warn 1, "Factory reset is disabled. Not resettings."
        {:noreply, %{state | not_found_timer: nil}}
      first_boot? ->
        msg = """
        Network not found after #{delay_minutes} minute(s).
        possible causes of this include:

        1) A typo if you manually inputted the SSID.

        2) The access point is out of range

        3) There is too much radio interference around Farmbot.

        5) There is a hardware issue.
        """
        Logger.error 1, msg
        Farmbot.System.factory_reset(msg)
        {:stop, %{state | not_found_timer: nil}}
      true ->
        Logger.error 1, "Network not found after timer. Farmbot is disconnected."
        msg = """
        Network not found after #{delay_minutes} minute(s).
        This can happen if your wireless access point is no longer available,
        out of range, or there is too much radio interference around Farmbot.
        If you see this message intermittently you should disable \"automatic
        factory reset\" or tune the \"network not found
        timer\" value in the Farmbot Web Application.
        """
        Farmbot.System.factory_reset(msg)
        # Network.teardown(state.interface)
        # Network.setup(state.interface, state.opts)
        {:stop, %{state | not_found_timer: nil}}
    end
  end

  def handle_info(:ntp_timer, state) do
    new_timer = restart_ntp_timer(state.ntp_timer)
    {:noreply, %{state | ntp_timer: new_timer}}
  end

  def handle_info(:dns_timer, state) do
    case test_dns() do
      {:ok, {:hostent, _host_name, aliases, :inet, 4, _}} ->
        # If we weren't previously connected, send a log.
        if state.connected do
          # Farmbot is still connected. NBD
          {:noreply, state}
        else
          Logger.success 3, "Farmbot was reconnected to the internet: #{inspect aliases}"
          new_state = %{state |
            connected: true,
            not_found_timer: cancel_timer(state.not_found_timer),
            dns_timer: restart_dns_timer(nil, 45_000),
            ntp_timer: restart_ntp_timer(state.ntp_timer, 1000)
          }
          Farmbot.System.Registry.dispatch(:network, :dns_up)
          {:noreply, new_state}
        end

      {:error, err} ->
        Farmbot.System.Registry.dispatch(:network, :dns_down)
        Logger.warn 3, "Farmbot was disconnected from the internet: #{inspect err}"
        Network.teardown(state.interface)
        Network.setup(state.interface, state.opts)
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

  defp restart_ntp_timer(timer, time \\ nil) do
    cancel_timer(timer)
    # introduce a bit of randomness to avoid dosing ntp servers.
    # I don't think this would ever happen but the default ntpd implementation
    # does this..
    rand = :rand.uniform(5000)

    case Ntp.set_time() do

      # If we Successfully set time, sync again in around 1024 seconds
      :ok -> Process.send_after(self(), :ntp_timer, (time || 1024000) + rand)
      # If time failed, try again in about 5 minutes.
      _ ->
        if Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "first_boot") do
          Process.send_after(self(), :ntp_timer, (time || 10_000) + rand)
        else
          Process.send_after(self(), :ntp_timer, (time || 300000) + rand)
        end
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
end
