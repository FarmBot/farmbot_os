defmodule FarmbotOS.Configurator.RouterTest do
  alias FarmbotOS.Configurator.Router
  use ExUnit.Case, async: true
  use Plug.Test

  alias FarmbotTest.Configurator.{MockDataLayer, MockNetworkLayer}
  import Mox
  setup :verify_on_exit!

  @opts Router.init([])

  test "index after reset" do
    MockDataLayer
    |> expect(:load_last_reset_reason, fn -> "whoops!" end)

    conn = conn(:get, "/")
    conn = Router.call(conn, @opts)
    assert conn.resp_body =~ "Configure"
    assert conn.resp_body =~ "<div class=\"last-shutdown-reason\">"
    assert conn.resp_body =~ "whoops!"
  end

  test "redirect to index" do
    MockDataLayer
    |> expect(:load_last_reset_reason, fn -> nil end)

    conn = conn(:get, "/setup")
    conn = Router.call(conn, @opts)
    redir = redirected_to(conn)
    assert redir == "/"

    conn = conn(:get, redir)
    conn = Router.call(conn, @opts)
    redir = redirected_to(conn)
    assert redir == "/network"
  end

  test "celeryscript requests don't get listed as last reset reason" do
    MockDataLayer
    |> expect(:load_last_reset_reason, fn -> "CeleryScript request." end)

    conn = conn(:get, "/")
    conn = Router.call(conn, @opts)
    refute conn.resp_body =~ "CeleryScript request."
  end

  test "no reset reason" do
    MockDataLayer
    |> expect(:load_last_reset_reason, fn -> nil end)

    conn = conn(:get, "/")
    conn = Router.call(conn, @opts)
    refute conn.resp_body =~ "<div class=\"last-shutdown-reason\">"
  end

  test "captive portal" do
    conn = conn(:get, "/generate_204")
    conn = Router.call(conn, @opts)
    assert conn.status == 302

    conn = conn(:get, "/gen_204")
    conn = Router.call(conn, @opts)
    assert conn.status == 302
  end

  test "network index" do
    MockNetworkLayer
    |> expect(:list_interfaces, fn ->
      [
        {"eth0", %{mac_address: "aa:bb:cc:dd:ee"}},
        {"eth1", %{mac_address: "aa:bb:cc:dd:FF"}}
      ]
    end)

    conn = conn(:get, "/network")
    conn = Router.call(conn, @opts)
    assert conn.resp_body =~ "eth0"
  end

  test "select network sets session data" do
    conn = conn(:post, "select_interface")
    conn = Router.call(conn, @opts)
    assert redirected_to(conn) == "/network"

    conn = conn(:post, "select_interface", %{"interface" => "eth0"})
    conn = Router.call(conn, @opts)
    assert redirected_to(conn) == "/config_wired"
    assert get_session(conn, "ifname") == "eth0"

    conn = conn(:post, "select_interface", %{"interface" => "wlan0"})
    conn = Router.call(conn, @opts)
    assert redirected_to(conn) == "/config_wireless"
    assert get_session(conn, "ifname") == "wlan0"
  end

  test "config wired" do
    conn =
      conn(:get, "/config_wired")
      |> init_test_session(%{"ifname" => "eth0"})
      |> Router.call(@opts)

    assert conn.resp_body =~ "Advanced settings"
  end

  test "config wireless SSID list" do
    MockNetworkLayer
    |> expect(:scan, fn _ ->
      [
        %{
          ssid: "Test Network",
          bssid: "aa:bb:cc:dd:ee:ff",
          security: "WPA-PSK",
          level: 100
        }
      ]
    end)

    conn =
      conn(:get, "/config_wireless")
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert conn.resp_body =~ "Test Network"
  end

  test "config wireless" do
    # No SSID or SECURITY
    conn =
      conn(:post, "/config_wireless_step_1", %{})
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert redirected_to(conn) == "/config_wireless"

    # No SECURITY
    conn =
      conn(:post, "/config_wireless_step_1", %{"ssid" => "Test Network"})
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert redirected_to(conn) == "/config_wireless"

    conn =
      conn(:post, "/config_wireless_step_1", %{"ssid" => "Test Network", "security" => "NONE"})
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    refute conn.resp_body =~ "PSK"
    assert conn.resp_body =~ "Advanced settings"

    conn =
      conn(:post, "/config_wireless_step_1", %{"ssid" => "Test Network", "security" => "WPA-PSK"})
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert conn.resp_body =~ "PSK"
    assert conn.resp_body =~ "Advanced settings"

    conn =
      conn(:post, "/config_wireless_step_1", %{"ssid" => "Test Network", "security" => "WPA2-PSK"})
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert conn.resp_body =~ "PSK"
    assert conn.resp_body =~ "Advanced settings"

    conn =
      conn(:post, "/config_wireless_step_1", %{"ssid" => "Test Network", "security" => "WPA-EAP"})
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    refute conn.resp_body =~ "PSK"
    assert conn.resp_body =~ "IDENTITY"
    assert conn.resp_body =~ "PASSWORD"
    assert conn.resp_body =~ "Advanced settings"

    conn =
      conn(:post, "/config_wireless_step_1", %{"manualssid" => "Test Network"})
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert conn.resp_body =~ "PSK"
    assert conn.resp_body =~ "EAP Identity"
    assert conn.resp_body =~ "EAP Password"
    assert conn.resp_body =~ "Advanced settings"

    conn =
      conn(:post, "/config_wireless_step_1", %{
        "ssid" => "Test Network",
        "security" => "WPA-UNSUPPORTED"
      })
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert conn.resp_body =~ "unknown or unsupported"
  end

  test "config_network" do
    params = %{
      "dns_name" => "super custom",
      "ntp_server_1" => "pool0.ntpd.org",
      "ntp_server_2" => "pool1.ntpd.org",
      "ssh_key" => "very long ssh key",
      "ssid" => "Test Network",
      "security" => "WPA-PSK",
      "psk" => "ABCDEF",
      "identity" => "NOT TECHNICALLY POSSIBLE",
      "password" => "NOT TECHNICALLY POSSIBLE",
      "domain" => "farmbot.org",
      "name_servers" => "192.168.1.1, 192.168.1.2",
      "ipv4_method" => "static",
      "ipv4_address" => "192.168.1.100",
      "ipv4_gateway" => "192.168.1.1",
      "ipv4_subnet_mask" => "255.255.0.0",
      "regulatory_domain" => "US"
    }

    conn =
      conn(:post, "/config_network", params)
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert get_session(conn, "net_config_dns_name") == "super custom"
    assert get_session(conn, "net_config_ntp1") == "pool0.ntpd.org"
    assert get_session(conn, "net_config_ntp2") == "pool1.ntpd.org"
    assert get_session(conn, "net_config_ssh_key") == "very long ssh key"
    assert get_session(conn, "net_config_ssid") == "Test Network"
    assert get_session(conn, "net_config_security") == "WPA-PSK"
    assert get_session(conn, "net_config_psk") == "ABCDEF"
    assert get_session(conn, "net_config_identity") == "NOT TECHNICALLY POSSIBLE"
    assert get_session(conn, "net_config_password") == "NOT TECHNICALLY POSSIBLE"
    assert get_session(conn, "net_config_domain") == "farmbot.org"
    assert get_session(conn, "net_config_name_servers") == "192.168.1.1, 192.168.1.2"
    assert get_session(conn, "net_config_ipv4_method") == "static"
    assert get_session(conn, "net_config_ipv4_address") == "192.168.1.100"
    assert get_session(conn, "net_config_ipv4_gateway") == "192.168.1.1"
    assert get_session(conn, "net_config_ipv4_subnet_mask") == "255.255.0.0"
    assert get_session(conn, "net_config_reg_domain") == "US"
    assert redirected_to(conn) == "/credentials"
  end

  test "credentials index" do
    MockDataLayer
    |> expect(:load_email, fn -> "test@test.org" end)
    |> expect(:load_password, fn -> "password123" end)
    |> expect(:load_server, fn -> "https://my.farm.bot" end)

    conn = conn(:get, "/credentials") |> Router.call(@opts)
    assert conn.resp_body =~ "test@test.org"
    assert conn.resp_body =~ "password123"
    assert conn.resp_body =~ "https://my.farm.bot"
  end

  test "configure credentials" do
    params = %{
      "email" => "test@test.org",
      "password" => "password123",
      "server" => "https://my.farm.bot"
    }

    conn =
      conn(:post, "/configure_credentials", params)
      |> Router.call(@opts)

    assert redirected_to(conn) == "/finish"
    assert get_session(conn, "auth_config_email") == "test@test.org"
    assert get_session(conn, "auth_config_password") == "password123"
    assert get_session(conn, "auth_config_server") == "https://my.farm.bot"

    conn =
      conn(:post, "/configure_credentials", %{params | "server" => "whoops/i/made/a/type"})
      |> Router.call(@opts)

    assert redirected_to(conn) == "/credentials"

    conn =
      conn(:post, "/configure_credentials", %{})
      |> Router.call(@opts)

    assert redirected_to(conn) == "/credentials"
  end

  test "finish" do
    conn =
      conn(:get, "/finish")
      |> Router.call(@opts)

    assert redirected_to(conn) == "/"
  end

  test "404" do
    conn =
      conn(:get, "/whoops")
      |> Router.call(@opts)

    assert conn.resp_body == "Page not found"
  end

  test "500" do
    MockNetworkLayer
    |> expect(:scan, fn _ ->
      [
        %{
          incorrect: :data
        }
      ]
    end)

    conn =
      conn(:get, "/config_wireless")
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert conn.status == 500
  end

  # Stolen from https://github.com/phoenixframework/phoenix/blob/3f157c30ceae8d1eb524fdd05b5e3de10e434c42/lib/phoenix/test/conn_test.ex#L438
  defp redirected_to(conn, status \\ 302)

  defp redirected_to(%Plug.Conn{state: :unset}, _status) do
    raise "expected connection to have redirected but no response was set/sent"
  end

  defp redirected_to(conn, status) when is_atom(status) do
    redirected_to(conn, Plug.Conn.Status.code(status))
  end

  defp redirected_to(%Plug.Conn{status: status} = conn, status) do
    location = Plug.Conn.get_resp_header(conn, "location") |> List.first()
    location || raise "no location header was set on redirected_to"
  end

  defp redirected_to(conn, status) do
    raise "expected redirection with status #{status}, got: #{conn.status}"
  end
end
