defmodule Farmbot.Target.Bootstrap.Configurator.CaptivePortal do
  use GenServer
  require Farmbot.Logger

  @interface Application.get_env(:farmbot_os, :captive_portal_interface, "wlan0")
  @address Application.get_env(:farmbot_os, :captive_portal_address, "192.168.25.1")
  @mdns_domain "farmbot-setup.local"

  @dnsmasq_conf_file "dnsmasq.conf"
  @dnsmasq_pid_file "dnsmasq.pid"

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Farmbot.Logger.busy(3, "Starting captive portal.")
    ensure_interface(@interface)

    Nerves.Network.teardown(@interface)

    host_ap_opts = [
      ssid: build_ssid(),
      key_mgmt: :NONE,
      mode: 2,
      # ap_scan: 0,
      # scan_ssid: 1,
    ]
    Nerves.Network.setup(@interface, host_ap_opts)

    ip_opts = [
      ipv4_address_method: :static,
      ipv4_address: @address, ipv4_subnet_mask: "255.255.0.0",
      nameservers: [@address]
    ]

    Nerves.NetworkInterface.setup(@interface, ip_opts)

    dhcp_opts = [
      gateway: @address,
      netmask: "255.255.255.0",
      range: {dhcp_range_begin(@address), dhcp_range_end(@address)},
      domain_servers: [@address],
    ]
    {:ok, dhcp_server} = DHCPServer.start_link(@interface, dhcp_opts)

    dnsmasq =
      case setup_dnsmasq(@address, @interface) do
        {:ok, dnsmasq} -> dnsmasq
        {:error, _} ->
          Farmbot.Logger.error 1, "Failed to start DnsMasq"
          nil
      end

    wpa_pid = wait_for_wpa()
    Nerves.WpaSupplicant.request(wpa_pid, {:AP_SCAN, 2})
    Farmbot.Leds.blue(:slow_blink)
    init_mdns(@mdns_domain)
    update_mdns(@address)
    {:ok, %{dhcp_server: dhcp_server, dnsmasq: dnsmasq}}
  end

  defp wait_for_wpa do
    name = :"Nerves.WpaSupplicant.#{@interface}"
    GenServer.whereis(name) || wait_for_wpa()
  end

  def terminate(_, state) do
    Farmbot.Logger.busy 3, "Stopping captive portal GenServer."

    Farmbot.Logger.busy 3, "Stopping mDNS."
    Mdns.Server.stop()

    Farmbot.Logger.busy 3, "Stopping DHCP GenServer."
    GenServer.stop(state.dhcp_server, :normal)

    stop_dnsmasq(state)

    Nerves.Network.teardown(@interface)
    Nerves.NetworkInterface.ifdown(@interface)
    do_teardown(@interface)
  end

  defp do_teardown(interface) do
    case Nerves.NetworkInterface.status(interface) do
      {:ok, %{operstate: :down}} -> :ok
      {:ok, %{operstate: :up}} ->
        Farmbot.Logger.busy 3, "Trying to stop #{interface}."
        Process.sleep(1000)
        Nerves.NetworkInterface.ifdown(interface)
        do_teardown(interface)
    end
  end

  def handle_info({_port, {:data, _data}}, state) do
    {:noreply, state}
  end

  defp dhcp_range_begin(address) do
    [a, b, c, _] = String.split(address, ".")
    Enum.join([a, b, c, "2"], ".")
  end

  defp dhcp_range_end(address) do
    [a, b, c, _] = String.split(address, ".")
    Enum.join([a, b, c, "10"], ".")
  end

  defp ensure_interface(interface) do
    unless interface in Nerves.NetworkInterface.interfaces() do
      Farmbot.Logger.debug 2, "Waiting for #{interface}: #{inspect Nerves.NetworkInterface.interfaces()}"
      Process.sleep(100)
      ensure_interface(interface)
    end
  end

  defp build_ssid do
    node_str = node() |> Atom.to_string()
    case node_str |> String.split("@") do
      [name, "farmbot-" <> id] -> name <> "-" <> id
      _ -> "Farmbot"
    end
  end

  defp setup_dnsmasq(ip_addr, interface) do
    dnsmasq_conf = build_dnsmasq_conf(ip_addr, interface)
    File.mkdir_p!("/tmp/dnsmasq")
    :ok = File.write("/tmp/dnsmasq/#{@dnsmasq_conf_file}", dnsmasq_conf)
    dnsmasq_cmd = "dnsmasq -k --dhcp-lease " <>
                  "/tmp/dnsmasq/#{@dnsmasq_pid_file} " <>
                  "--conf-dir=/tmp/dnsmasq"
    dnsmasq_port = Port.open({:spawn, dnsmasq_cmd}, [:binary])
    get_dnsmasq_info(dnsmasq_port, ip_addr, interface)
  end

  defp get_dnsmasq_info(nil, ip_addr, interface) do
    Farmbot.Logger.warn 1, "dnsmasq failed to start."
    Process.sleep(1000)
    setup_dnsmasq(ip_addr, interface)
  end

  defp get_dnsmasq_info(dnsmasq_port, ip_addr, interface) when is_port(dnsmasq_port) do
    case Port.info(dnsmasq_port, :os_pid) do
      {:os_pid, dnsmasq_os_pid} ->
        {dnsmasq_port, dnsmasq_os_pid}
      nil ->
        Farmbot.Logger.warn 1, "dnsmasq not ready yet."
        Process.sleep(1000)
        setup_dnsmasq(ip_addr, interface)
    end
  end

  defp build_dnsmasq_conf(ip_addr, interface) do
    """
    interface=#{interface}
    address=/#/#{ip_addr}
    server=/farmbot/#{ip_addr}
    local=/farmbot/
    domain=farmbot
    """
  end

  defp stop_dnsmasq(state) do
    case state.dnsmasq do
      {dnsmasq_port, dnsmasq_os_pid} ->
        Farmbot.Logger.busy 3, "Stopping dnsmasq"
        Farmbot.Logger.busy 3, "Killing dnsmasq PID."
        :ok = kill(dnsmasq_os_pid)
        Port.close(dnsmasq_port)
        Farmbot.Logger.success 3, "Stopped dnsmasq."
        :ok
      _ ->
        Farmbot.Logger.debug 3, "Dnsmasq not running."
        :ok
    end
  rescue
    e ->
      Farmbot.Logger.error 3, "Error stopping dnsmasq: #{Exception.message(e)}"
      :ok
  end

  defp kill(os_pid), do: :ok = cmd("kill -9 #{os_pid}")

  defp cmd(cmd_str) do
    [command | args] = String.split(cmd_str, " ")
    System.cmd(command, args, into: IO.stream(:stdio, :line))
    |> print_cmd()
  end

  defp print_cmd({_, 0}), do: :ok

  defp print_cmd({_, num}) do
    Farmbot.Logger.error(2, "Encountered an error (#{num})")
    :error
  end

  defp init_mdns(mdns_domain) do
    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: mdns_domain,
      data: :ip,
      ttl: 120,
      type: :a
    })
  end

  defp update_mdns(ip) do
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
