defmodule Hostapd do
  @moduledoc """
  Manages an OS process of hostapd.
  """

  defmodule State do
    @moduledoc false
    defstruct [:hostapd, :dnsmasq, :interface, :ip_addr]
  end

  use GenServer
  use Farmbot.Logger

  @hostapd_conf_file "hostapd.conf"
  @hostapd_pid_file "hostapd.pid"

  @dnsmasq_conf_file "dnsmasq.conf"
  @dnsmasq_pid_file "dnsmasq.pid"

  defp ensure_interface(interface) do
    unless interface in Nerves.NetworkInterface.interfaces() do
      Logger.debug 2, "Waiting for #{interface}: #{inspect Nerves.NetworkInterface.interfaces()}"
      Process.sleep(100)
      ensure_interface(interface)
    end
  end

  @doc false
  def start_link(opts, gen_server_opts \\ []) do
    GenServer.start_link(__MODULE__, opts, gen_server_opts)
  end

  def init(opts) do
    # We want to know if something does.
    Process.flag(:trap_exit, true)
    interface = Keyword.fetch!(opts, :interface)
    address = Keyword.fetch!(opts, :address)
    Logger.busy(3, "Starting hostapd on #{interface}")
    ensure_interface(interface)

    dnsmasq_path = System.find_executable("dnsmasq")
    dnsmasq_settings = if dnsmasq_path do
      setup_dnsmasq(address, interface)
    else
      nil
    end

    {hostapd_port, hostapd_os_pid} = setup_hostapd(interface, address)

    state = %State{
      hostapd: {hostapd_port, hostapd_os_pid},
      dnsmasq: dnsmasq_settings,
      interface: interface,
      ip_addr: address
    }

    {:ok, state}
  end


  defp setup_dnsmasq(ip_addr, interface) do
    dnsmasq_conf = build_dnsmasq_conf(ip_addr, interface)
    File.mkdir!("/tmp/dnsmasq")
    :ok = File.write("/tmp/dnsmasq/#{@dnsmasq_conf_file}", dnsmasq_conf)
    dnsmasq_cmd = "dnsmasq -k --dhcp-lease " <>
                  "/tmp/dnsmasq/#{@dnsmasq_pid_file} " <>
                  "--conf-dir=/tmp/dnsmasq"
    dnsmasq_port = Port.open({:spawn, dnsmasq_cmd}, [:binary])
    dnsmasq_os_pid = dnsmasq_port|> Port.info() |> Keyword.get(:os_pid)
    {dnsmasq_port, dnsmasq_os_pid}
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

  defp setup_hostapd(interface, ip_addr) do
    # Make sure the interface is in proper condition.
    :ok = hostapd_ip_settings_up(interface, ip_addr)
    # build the hostapd configuration
    hostapd_conf = build_hostapd_conf(interface, build_ssid())
    # build a config file
    File.mkdir!("/tmp/hostapd")
    File.write!("/tmp/hostapd/#{@hostapd_conf_file}", hostapd_conf)

    hostapd_cmd =
      "hostapd -P /tmp/hostapd/#{@hostapd_pid_file} " <> "/tmp/hostapd/#{@hostapd_conf_file}"

    hostapd_port = Port.open({:spawn, hostapd_cmd}, [:binary])
    hostapd_os_pid = hostapd_port |> Port.info() |> Keyword.get(:os_pid)
    {hostapd_port, hostapd_os_pid}
  end

  defp hostapd_ip_settings_up(interface, ip_addr) do
    :ok =
      "ip"
      |> System.cmd(["link", "set", "#{interface}", "up"])
      |> print_cmd

    :ok =
      "ip"
      |> System.cmd(["addr", "add", "#{ip_addr}/24", "dev", "#{interface}"])
      |> print_cmd

    :ok
  end

  defp hostapd_ip_settings_down(interface, ip_addr) do
    :ok =
      "ip"
      |> System.cmd(["link", "set", "#{interface}", "down"])
      |> print_cmd

    :ok =
      "ip"
      |> System.cmd(["addr", "del", "#{ip_addr}/24", "dev", "#{interface}"])
      |> print_cmd

    :ok =
      "ip"
      |> System.cmd(["link", "set", "#{interface}", "up"])
      |> print_cmd

    :ok
  end

  defp build_hostapd_conf(interface, ssid) do
    """
    interface=#{interface}
    ssid=#{ssid}
    hw_mode=g
    channel=6
    auth_algs=1
    wmm_enabled=0
    """
  end

  defp build_ssid do
    node_str = node() |> Atom.to_string()
    case node_str |> String.split("@") do
      [name, "farmbot-" <> id] ->
        name <> "-" <> id
      _ -> "Farmbot"
    end
  end

  defp kill(os_pid), do: :ok = "kill" |> System.cmd(["9", "#{os_pid}"]) |> print_cmd

  defp print_cmd({_, 0}), do: :ok

  defp print_cmd({res, num}) do
    Logger.error(2, "Encountered an error (#{num}): #{res}")
    :error
  end

  def handle_info({port, {:data, data}}, state) do
    {hostapd_port, _} = state.hostapd

    cond do
      port == hostapd_port ->
        handle_hostapd(data, state)
      match?({^port, _}, state.dnsmasq) ->
        handle_dnsmasq(data, state)
      true ->
        {:noreply, state}
    end
  end

  def handle_info(_, state), do: {:noreply, state}

  defp handle_hostapd(data, state) when is_bitstring(data) do
    Logger.debug(3, String.trim(data))
    {:noreply, state}
  end

  defp handle_dnsmasq(data, state) when is_bitstring(data) do
    Logger.debug(3, String.trim(data))
    {:noreply, state}
  end

  def terminate(_, state) do
    Logger.busy 3, "Stopping hostapd"
    {hostapd_port, hostapd_pid} = state.hostapd
    Logger.busy 3, "Killing hostapd PID."
    :ok = kill(hostapd_pid)
    Logger.busy 3, "Resetting ip settings."
    hostapd_ip_settings_down(state.interface, state.ip_addr)
    Logger.busy 3, "removing PID."
    File.rm_rf!("/tmp/hostapd")

    if state.dnsmasq do
      Logger.busy 3, "Stopping dnsmasq"
      {dnsmasq_port, dnsmasq_os_pid} = state.dnsmasq
      Logger.busy 3, "Killing dnsmasq PID."
      :ok = kill(dnsmasq_os_pid)
      Port.close(dnsmasq_port)
    end
    Logger.success 3, "Done."
    Port.close(hostapd_port)
    :ok
  rescue
    _e in ArgumentError -> :ok
  end
end
