defmodule FarmbotOS.Configurator.ConfigDataLayerTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.Configurator.ConfigDataLayer

  test "works" do
    params = %{
      "auth_config_email" => "test@test.com",
      "auth_config_password" => "password123",
      "auth_config_server" => "http://localhost:3000",
      "ifname" => "eth0",
      "iftype" => "wired",
      "net_config_dns_name" => nil,
      "net_config_domain" => nil,
      "net_config_identity" => nil,
      "net_config_ipv4_address" => "0.0.0.0",
      "net_config_ipv4_gateway" => "0.0.0.0",
      "net_config_ipv4_method" => "dhcp",
      "net_config_ipv4_subnet_mask" => "255.255.0.0",
      "net_config_name_servers" => nil,
      "net_config_ntp1" => nil,
      "net_config_ntp2" => nil,
      "net_config_password" => nil,
      "net_config_psk" => nil,
      "net_config_reg_domain" => "US",
      "net_config_security" => nil,
      "net_config_ssh_key" => nil,
      "net_config_ssid" => nil
    }

    assert :ok == ConfigDataLayer.save_config(params)
  end
end
