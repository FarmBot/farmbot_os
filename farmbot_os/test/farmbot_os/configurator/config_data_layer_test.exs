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

    expected = %{
      domain: nil,
      identity: nil,
      ipv4_address: "0.0.0.0",
      ipv4_gateway: "0.0.0.0",
      ipv4_method: "dhcp",
      ipv4_subnet_mask: "255.255.0.0",
      name: "eth0",
      name_servers: nil,
      password: nil,
      psk: nil,
      regulatory_domain: "US",
      security: nil,
      ssid: nil,
      type: "wired"
    }

    FarmbotCore.Config
    |> expect(:input_network_config!, 1, fn network_params ->
      assert expected == network_params
    end)
    |> expect(:update_config_value, 1, fn :string,
                                          "authorization",
                                          "email",
                                          auth_config_email ->
      assert :x == auth_config_email
      :ok
    end)
    |> expect(:update_config_value, 1, fn :string,
                                          "authorization",
                                          "password",
                                          auth_config_password ->
      assert :x == auth_config_password
      :ok
    end)
    |> expect(:update_config_value, 1, fn :string,
                                          "authorization",
                                          "server",
                                          auth_config_server ->
      assert :x == auth_config_server
      :ok
    end)
    |> expect(:update_config_value, 1, fn :string,
                                          "settings",
                                          "default_dns_name",
                                          net_config_dns_name ->
      assert :x == net_config_dns_name
      :ok
    end)
    |> expect(:update_config_value, 1, fn :string,
                                          "settings",
                                          "default_ntp_server_1",
                                          nil ->
      :ok
    end)
    |> expect(:update_config_value, 1, fn :string,
                                          "settings",
                                          "default_ntp_server_2",
                                          nil ->
      :ok
    end)
    |> expect(:update_config_value, 1, fn :string,
                                          "authorization",
                                          "secret",
                                          nil ->
      :ok
    end)

    assert :ok == ConfigDataLayer.save_config(params)
  end
end
