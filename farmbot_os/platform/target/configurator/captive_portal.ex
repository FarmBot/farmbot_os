defmodule FarmbotOS.Platform.Target.Configurator.CaptivePortal do
  @moduledoc """
  VintageNet Technology that handles redirecting 
  **all** traffic to Farmbot's configuration interface
  """

  @behaviour VintageNet.Technology
  require FarmbotCore.Logger
  alias FarmbotOS.Configurator.CaptiveDNS

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
    |> add_captive_dns()
  end

  def to_raw_config(ifname, config, opts) do
    normalized = normalize(config)

    ifname
    |> vintage_ethernet(normalized, opts)
    |> add_captive_dns()
  end

  @impl VintageNet.Technology
  def check_system(opts) do
    VintageNetWiFi.check_system(opts)
  end

  @impl true
  def ioctl(ifname, ioctl, args) do
    VintageNetWiFi.ioctl(ifname, ioctl, args)
  end

  defp add_captive_dns(%{ifname: ifname} = raw_config) do
    child_specs = [
      {CaptiveDNS, [ifname, 53]}
    ]

    %{raw_config | child_specs: raw_config.child_specs ++ child_specs}
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
