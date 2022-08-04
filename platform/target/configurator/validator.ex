defmodule FarmbotOS.Platform.Target.Configurator.Validator do
  @moduledoc """
  VintageNet.Technology that handles turning Farmbot's internal
  network representation into either a VintageNetEthernet
  or VintageNetWiFi RawConfig.
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
    config
  end

  def normalize(_) do
    raise "Could not normalize farmbot network config"
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
      type: VintageNetEthernet,
      ipv4: to_ipv4(config)
    }

    vintage_ethernet(ifname, config, opts)
  end

  def to_wireless_raw_config(ifname, config, opts) do
    config = %{
      type: VintageNetWiFi,
      ipv4: to_ipv4(config),
      vintage_net_wifi: to_vintage_net_wifi(config)
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
         name_servers: name_servers,
         domain: domain,
         ipv4_address: ipv4_address,
         ipv4_gateway: ipv4_gateway,
         ipv4_subnet_mask: ipv4_subnet_mask
       }) do
    %{
      method: :static,
      address: ipv4_address,
      netmask: ipv4_subnet_mask,
      gateway: ipv4_gateway,
      name_servers: name_servers,
      domain: domain
    }
  end

  defp to_ipv4(%{ipv4_method: "dhcp"}) do
    %{method: :dhcp}
  end

  defp to_vintage_net_wifi(%{
         security: "NONE",
         ssid: ssid,
         regulatory_domain: reg_domain
       }) do
    %{
      networks: [
        %{
          key_mgmt: :none,
          ssid: ssid,
          scan_ssid: 1
        }
      ],
      bgscan: :simple,
      regulatory_domain: reg_domain
    }
  end

  defp to_vintage_net_wifi(%{
         security: "WPA-PSK",
         ssid: ssid,
         psk: psk,
         regulatory_domain: reg_domain
       }) do
    %{
      networks: [
        %{
          ssid: ssid,
          psk: psk,
          key_mgmt: :wpa_psk,
          scan_ssid: 1
        }
      ],
      bgscan: :simple,
      regulatory_domain: reg_domain
    }
  end

  defp to_vintage_net_wifi(%{
         security: "WPA2-PSK",
         ssid: ssid,
         psk: psk,
         regulatory_domain: reg_domain
       }) do
    %{
      networks: [
        %{
          ssid: ssid,
          key_mgmt: :wpa_psk,
          psk: psk,
          scan_ssid: 1
        }
      ],
      bgscan: :simple,
      regulatory_domain: reg_domain
    }
  end

  defp to_vintage_net_wifi(%{
         security: "WPA-EAP",
         ssid: ssid,
         identity: id,
         password: pw,
         regulatory_domain: reg_domain
       }) do
    %{
      networks: [
        %{
          ssid: ssid,
          key_mgmt: :wpa_eap,
          pairwise: "CCMP TKIP",
          group: "CCMP TKIP",
          eap: "PEAP",
          phase1: "peapver=auto",
          phase2: "MSCHAPV2",
          identity: id,
          password: pw,
          scan_ssid: 1
        }
      ],
      bgscan: :simple,
      regulatory_domain: reg_domain
    }
  end

  defp vintage_ethernet(ifname, config, opts) do
    config = VintageNetEthernet.normalize(config)
    VintageNetEthernet.to_raw_config(ifname, config, opts)
  end

  defp vintage_wifi(ifname, config, opts) do
    config = VintageNetWiFi.normalize(config)
    VintageNetWiFi.to_raw_config(ifname, config, opts)
  end
end
