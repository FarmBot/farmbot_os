defmodule FarmbotOS.Platform.Target.Configurator.CaptivePortal do
  @moduledoc """
  Handles turning Farmbot's internal network representation into
  either a VintageNet.Technology.Ethernet or VintageNet.Technology.WiFi
  RawConfig.
  """
  @behaviour VintageNet.Technology
  require FarmbotCore.Logger

  @impl VintageNet.Technology
  def normalize(config) do
    %{config | type: VintageNet.Technology.WiFi}
    |> VintageNet.Technology.WiFi.normalize()
  end

  @impl VintageNet.Technology
  def to_raw_config(ifname, config, opts) do
    {:ok, normalized} = normalize(config)

    ifname
    |> vintage_wifi(normalized, opts)
    |> dnsmasq(opts)
  end

  @impl VintageNet.Technology
  def check_system(opts) do
    VintageNet.Technology.WiFi.check_system(opts)
  end

  @impl true
  def ioctl(ifname, ioctl, args) do
    VintageNet.Technology.WiFi.ioctl(ifname, ioctl, args)
  end

  defp dnsmasq(%{ifname: ifname, source_config: %{dnsmasq: config}} = raw_config, opts) do
    tmpdir = Keyword.fetch!(opts, :tmpdir)
    killall = Keyword.fetch!(opts, :bin_killall)
    dnsmasq = System.find_executable("dnsmasq")
    dnsmasq_conf_path = Path.join(tmpdir, "dnsmasq.conf.#{ifname}")
    dnsmasq_lease_file = Path.join(tmpdir, "dnsmasq.leases.#{ifname}")
    dnsmasq_pid_file = Path.join(tmpdir, "dnsmasq.pid.#{ifname}")

    dnsmasq_conf_contents = """
    interface=#{ifname}
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
          raw_config.cleanup_files ++ [dnsmasq_conf_path, dnsmasq_lease_file, dnsmasq_pid_file]
    }

    {:ok, updated_raw_config}
  end

  defp dnsmasq(%{} = raw_config, _opts) do
    FarmbotCore.Logger.error(1, "DNSMASQ Disabled")
    {:ok, raw_config}
  end

  defp vintage_wifi(ifname, config, opts) do
    with {:ok, config} <- VintageNet.Technology.WiFi.normalize(config),
         {:ok, raw_config} <- VintageNet.Technology.WiFi.to_raw_config(ifname, config, opts) do
      %{raw_config | type: VintageNet.Technology.WiFi}
    end
  end
end
