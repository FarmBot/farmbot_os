defmodule Farmbot.System.Network.Hostapd do
  @moduledoc """
    Manages an OS process of hostapd and DNSMASQ.
  """

  defmodule State do
    @moduledoc false
    defstruct [:hostapd, :dnsmasq, :interface, :ip_addr, :manager]
  end

  use GenServer
  require Logger

  @hostapd_conf_file "hostapd.conf"
  @hostapd_pid_file  "hostapd.pid"

  @dnsmasq_conf_file "dnsmasq.conf"
  @dnsmasq_pid_file "dnsmasq.pid"

  @doc """
    Example:
      Iex> Hostapd.start_link ip_address: "192.168.24.1",
      ...> manager: Farmbot.Network.Manager, interface: "wlan0"
  """
  def start_link(
    [interface: interface, ip_address: ip_addr, manager: manager])
  do
    name = Module.concat([__MODULE__, interface])
    GenServer.start_link(__MODULE__,
          [interface: interface, ip_address: ip_addr, manager: manager],
          name: name)
  end

  # Don't lint this. Its not too complex credo.
  # No but really TODO: make this a little less complex.
  @lint false
  _ = @lint
  @doc false
  def init([interface: interface, ip_address: ip_addr, manager: manager]) do
    Logger.debug ">> is starting hostapd on #{interface}"
    # We want to know if something does.
    Process.flag :trap_exit, true
    # ip_addr = @ip_addr

    # HOSTAPD
    # Make sure the interface is in proper condition.
    :ok = hostapd_ip_settings_up(interface, ip_addr)
    # build the hostapd configuration
    hostapd_conf = build_hostapd_conf(interface, build_ssid())
    # build a config file
    File.mkdir! "/tmp/hostapd"
    File.write! "/tmp/hostapd/#{@hostapd_conf_file}", hostapd_conf
    hostapd_cmd = "hostapd -P /tmp/hostapd/#{@hostapd_pid_file} " <>
                  "/tmp/hostapd/#{@hostapd_conf_file}"
    hostapd_port = Port.open({:spawn, hostapd_cmd}, [:binary])
    hostapd_os_pid = Port.info(hostapd_port) |> Keyword.get(:os_pid)

    # DNSMASQ

    dnsmasq_conf = build_dnsmasq_conf(ip_addr)
    File.mkdir!("/tmp/dnsmasq")
    :ok = File.write("/tmp/dnsmasq/#{@dnsmasq_conf_file}", dnsmasq_conf)
    dnsmasq_cmd = "dnsmasq -k --dhcp-lease " <>
                  "/tmp/dnsmasq/#{@dnsmasq_pid_file} " <>
                  "--conf-dir=/tmp/dnsmasq"
    dnsmasq_port = Port.open({:spawn, dnsmasq_cmd}, [:binary])
    dnsmasq_os_pid = Port.info(dnsmasq_port) |> Keyword.get(:os_pid)

    state =  %State{hostapd: {hostapd_port, hostapd_os_pid},
                    dnsmasq: {dnsmasq_port, dnsmasq_os_pid},
                    interface: interface,
                    ip_addr: ip_addr,
                    manager: manager}
    {:ok,state}
  end

  @lint false # don't lint this because piping System.cmd looks weird to me.
  defp hostapd_ip_settings_up(interface, ip_addr) do
    :ok =
      System.cmd("ip", ["link", "set", "#{interface}", "up"])
      |> print_cmd
    :ok =
      System.cmd("ip", ["addr", "add", "#{ip_addr}/24", "dev", "#{interface}"])
      |> print_cmd
    :ok
  end

  @lint false # don't lint this because piping System.cmd looks weird to me.
  defp hostapd_ip_settings_down(interface, ip_addr) do
    :ok =
      System.cmd("ip", ["link", "set", "#{interface}", "down"])
      |> print_cmd
    :ok =
      System.cmd("ip", ["addr", "del", "#{ip_addr}/24", "dev", "#{interface}"])
      |> print_cmd
    :ok =
      System.cmd("ip", ["link", "set", "#{interface}", "up"])
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
    node_str =
      node() |> Atom.to_string
    [name, "nerves-" <> id] =
      node_str |> String.split("@")
    name <> "-" <> id
  end

  defp build_dnsmasq_conf(ip_addr) do
    [a, b, c, _] = ip_addr |> String.split(".")
    first_part = "#{a}.#{b}.#{c}."
    """
    # bogus-priv
    # server=/localnet/#{ip_addr}
    # local=/localnet/
    interface=wlan0
    # domain=localnet
    dhcp-range=#{first_part}50,#{first_part}250,2h
    dhcp-option=3,#{ip_addr}
    dhcp-option=6,#{ip_addr}
    dhcp-authoritative
    # address=/#/#{ip_addr}
    """
  end

  @lint false # don't lint this because piping System.cmd looks weird to me.
  defp kill(os_pid),
    do: :ok = System.cmd("kill", ["15", "#{os_pid}"]) |> print_cmd

defp print_cmd({_, 0}), do: :ok
  defp print_cmd({res, num}) do
    Logger.error ">> encountered an error (#{num}): #{res}"
    :error
  end

  def handle_info({port, {:data, data}}, state) do
    {hostapd_port,_} = state.hostapd
    {dnsmasq_port,_} = state.dnsmasq
    cond do
      port == hostapd_port ->
        handle_hostapd(data, state)
      port == dnsmasq_port ->
        handle_dnsmasq(data, state)
      true -> {:noreply, state}
    end
  end
  def handle_info(_thing, state), do: {:noreply, state}

  defp handle_hostapd(data, state) when is_bitstring(data) do
    GenEvent.notify(state.manager, {:hostapd, String.trim(data)})
    {:noreply, state}
  end
  defp handle_hostapd(_,state), do: {:noreply, state}

  defp handle_dnsmasq(data, state) when is_bitstring(data) do
    GenEvent.notify(state.manager, {:dnsmasq, String.trim(data)})
    {:noreply, state}
  end

  defp handle_dnsmasq(_,state), do: {:noreply, state}


  def terminate(_,state) do
    Logger.debug ">> is stopping hostapd"
    {_hostapd_port, hostapd_pid} = state.hostapd
    {_dnsmasq_port, dnsmasq_pid} = state.dnsmasq
    # Port.close hostapd_port
    # Port.close dnsmasq_port
    :ok = kill(hostapd_pid)
    :ok = kill(dnsmasq_pid)
    hostapd_ip_settings_down(state.interface, state.ip_addr)
    File.rm_rf! "/tmp/hostapd"
    File.rm_rf! "/tmp/dnsmasq"
  end
end
