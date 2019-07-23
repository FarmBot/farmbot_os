defmodule FarmbotOS.Platform.Target.Configurator.Validator do
  @moduledoc """
  Handles turning Farmbot's internal network representation into
  either a VintageNet.Technology.Ethernet or VintageNet.Technology.WiFi
  RawConfig.
  """
  @behaviour VintageNet.Technology

  @impl VintageNet.Technology
  def normalize(
        %{
          network_type: _,
          ssid: _,
          security: _,
          psk: _,
          identity: _,
          password: _,
          domain: _,
          name_servers: _,
          ipv4_method: _,
          ipv4_address: _,
          ipv4_gateway: _,
          ipv4_subnet_mask: _,
          regulatory_domain: _
        } = config
      ) do
    {:ok, config}
  end

  def normalize(_) do
    {:error, :incomplete_config}
  end

  @impl VintageNet.Technology
  def to_raw_config(ifname, %{network_type: type} = config, opts) do
    case type do
      "wired" -> to_wired_raw_config(ifname, config, opts)
      "wireless" -> to_wireless_raw_config(ifname, config, opts)
    end
  end

  def to_wired_raw_config(ifname, config, opts) do
    config = %{
      type: VintageNet.Technology.Ethernet,
      ipv4: to_ipv4(config)
    }

    vintage_ethernet(ifname, config, opts)
  end

  def to_wireless_raw_config(ifname, config, opts) do
    config = %{
      type: VintageNet.Technology.WiFi,
      ipv4: to_ipv4(config),
      wifi: to_wifi(config)
    }

    vintage_wifi(ifname, config, opts)
  end

  @impl VintageNet.Technology
  def check_system(_opts) do
    :ok
  end

  @impl true
  def ioctl(_ifname, _ioctl, _args) do
    {:error, :unsupported}
  end

  defp to_ipv4(%{
         ipv4_method: "static",
         # TODO(Connor) fix nameservers
         # name_servers: name_servers,
         # domain: domain,
         ipv4_address: ipv4_address,
         ipv4_gateway: ipv4_gateway,
         ipv4_subnet_mask: ipv4_subnet_mask
       }) do
    %{
      method: :static,
      address: ipv4_address,
      netmask: ipv4_subnet_mask,
      gateway: ipv4_gateway
    }
  end

  defp to_ipv4(%{ipv4_method: "dhcp"}) do
    %{method: :dhcp}
  end

  defp to_wifi(%{security: "NONE", ssid: ssid, regulatory_domain: reg_domain}) do
    %{
      key_mgmt: :none,
      ssid: ssid,
      scan_ssid: 1,
      bgscan: :simple,
      regulatory_domain: reg_domain
    }
  end

  defp to_wifi(%{security: "WPA-PSK", ssid: ssid, psk: psk, regulatory_domain: reg_domain}) do
    %{
      ssid: ssid,
      key_mgmt: :wpa_psk,
      psk: psk,
      scan_ssid: 1,
      bgscan: :simple,
      regulatory_domain: reg_domain
    }
  end

  defp to_wifi(%{security: "WPA2-PSK", ssid: ssid, psk: psk, regulatory_domain: reg_domain}) do
    %{
      ssid: ssid,
      key_mgmt: :wpa_psk,
      psk: psk,
      scan_ssid: 1,
      bgscan: :simple,
      regulatory_domain: reg_domain
    }
  end

  defp to_wifi(%{
         security: "WPA-EAP",
         ssid: ssid,
         identity: id,
         password: pw,
         regulatory_domain: reg_domain
       }) do
    %{
      ssid: ssid,
      key_mgmt: :wpa_eap,
      identity: id,
      password: pw,
      scan_ssid: 1,
      bgscan: :simple,
      regulatory_domain: reg_domain
    }
  end

  defp vintage_ethernet(ifname, config, opts) do
    with {:ok, config} <- VintageNet.Technology.Ethernet.normalize(config),
         do: VintageNet.Technology.Ethernet.to_raw_config(ifname, config, opts)
  end

  defp vintage_wifi(ifname, config, opts) do
    with {:ok, config} <- VintageNet.Technology.WiFi.normalize(config),
         do: VintageNet.Technology.WiFi.to_raw_config(ifname, config, opts)
  end
end
