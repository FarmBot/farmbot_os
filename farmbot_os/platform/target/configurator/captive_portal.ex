defmodule FarmbotOS.Platform.Target.Configurator.CaptivePortal do
  @moduledoc """
  VintageNet Technology that handles redirecting 
  **all** traffic to Farmbot's configuration interface
  """

  @behaviour VintageNet.Technology
  require FarmbotCore.Logger

  @impl VintageNet.Technology
  def normalize(%{vintage_net_wifi: _} = config) do
    %{config | type: VintageNetWiFi}
    |> VintageNetWiFi.normalize()
  end

  def normalize(config) do
    %{config | type: VintageNetEthernet}
    |> VintageNetEthernet.normalize()
  end

  @impl VintageNet.Technology
  def to_raw_config(ifname, %{vintage_net_wifi: _} = config, opts) do
    normalized = normalize(config)

    ifname
    |> vintage_wifi(normalized, opts)
    |> dnsmasq(opts)
  end

  def to_raw_config(ifname, config, opts) do
    normalized = normalize(config)

    ifname
    |> vintage_ethernet(normalized, opts)
    |> dnsmasq(opts)
  end

  @impl VintageNet.Technology
  def check_system(opts) do
    VintageNetWiFi.check_system(opts)
  end

  @impl true
  def ioctl(ifname, ioctl, args) do
    VintageNetWiFi.ioctl(ifname, ioctl, args)
  end

  defp dnsmasq(
         %{ifname: ifname, source_config: %{dnsmasq: config}} = raw_config,
         opts
       ) do
    tmpdir = Keyword.fetch!(opts, :tmpdir)
    killall = Keyword.fetch!(opts, :bin_killall)
    dnsmasq = System.find_executable("dnsmasq")
    dnsmasq_conf_path = Path.join(tmpdir, "dnsmasq.conf.#{ifname}")
    dnsmasq_lease_file = Path.join(tmpdir, "dnsmasq.leases.#{ifname}")
    dnsmasq_pid_file = Path.join(tmpdir, "dnsmasq.pid.#{ifname}")

    dnsmasq_conf_contents = """
    interface=#{ifname}
    except-interface=lo
    localise-queries
    bogus-priv
    bind-interfaces
    listen-address=#{config[:address]}
    server=#{config[:address]}
    address=/#/#{config[:address]}
    dhcp-option=6,#{config[:address]}
    dhcp-range=#{config[:start]},#{config[:end]},12h
    """

    files = [
      {dnsmasq_conf_path, dnsmasq_conf_contents}
    ]

    up_cmds = [
      {:run, dnsmasq,
       [
         "-K",
         "-l",
         dnsmasq_lease_file,
         "-x",
         dnsmasq_pid_file,
         "-C",
         dnsmasq_conf_path
       ]}
    ]

    down_cmds = [
      {:run, killall, ["-q", "-9", "dnsmasq"]}
    ]

    updated_raw_config = %{
      raw_config
      | files: raw_config.files ++ files,
        up_cmds: raw_config.up_cmds ++ up_cmds,
        down_cmds: raw_config.down_cmds ++ down_cmds,
        cleanup_files:
          raw_config.cleanup_files ++
            [dnsmasq_conf_path, dnsmasq_lease_file, dnsmasq_pid_file]
    }

    updated_raw_config
  end

  defp dnsmasq(%{} = raw_config, _opts) do
    FarmbotCore.Logger.error(1, "DNSMASQ Disabled")
    raw_config
  end

  defp vintage_wifi(ifname, config, opts) do
    config = VintageNetWiFi.normalize(config)
    raw_config = VintageNetWiFi.to_raw_config(ifname, config, opts)
    %{raw_config | type: VintageNetWiFi}
  end

  defp vintage_ethernet(ifname, config, opts) do
    config = VintageNetEthernet.normalize(config)
    raw_config = VintageNetEthernet.to_raw_config(ifname, config, opts)
    %{raw_config | type: VintageNetEthernet}
  end
end
