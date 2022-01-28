defmodule FarmbotOS.Configurator.ConfigDataLayerTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.Configurator.ConfigDataLayer

  @fake_params %{
    "auth_config_email" => System.get_env("FARMBOT_EMAIL", "test@test.com"),
    "auth_config_password" => System.get_env("FARMBOT_PASSWORD", "password123"),
    "auth_config_server" =>
      System.get_env("FARMBOT_SERVER", "http://localhost:3000"),
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
    "net_config_ssid" => nil
  }

  test "failure: load_last_reset_reason" do
    expect(File, :read, 1, fn _ -> nil end)
    assert nil == ConfigDataLayer.load_last_reset_reason()
  end

  test "success: load_last_reset_reason" do
    expect(File, :read, 1, fn _ -> {:ok, "testcase123"} end)
    assert "testcase123" == ConfigDataLayer.load_last_reset_reason()
  end

  test "load_(server|email|password)()" do
    :ok = ConfigDataLayer.save_config(@fake_params)
    assert @fake_params["auth_config_server"] == ConfigDataLayer.load_server()

    assert @fake_params["auth_config_password"] ==
             ConfigDataLayer.load_password()

    assert @fake_params["auth_config_email"] == ConfigDataLayer.load_email()
  end

  test "works" do
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

    FarmbotOS.Config
    |> expect(:input_network_config!, 1, fn network_params ->
      assert expected == network_params
    end)
    |> expect(:update_config_value, 7, fn
      :string, "authorization", "email", email ->
        assert email == @fake_params["auth_config_email"]
        :ok

      :string, "authorization", "password", pass ->
        assert pass == @fake_params["auth_config_password"]
        :ok

      :string, "authorization", "server", server ->
        assert server == @fake_params["auth_config_server"]
        :ok

      :string, "settings", "default_dns_name", nil ->
        :ok

      :string, "settings", "default_ntp_server_1", nil ->
        :ok

      :string, "settings", "default_ntp_server_2", nil ->
        :ok

      :string, "authorization", "secret", nil ->
        :ok

      _, _, _, _ ->
        raise "NEVER"
    end)

    assert :ok == ConfigDataLayer.save_config(@fake_params)
  end
end
