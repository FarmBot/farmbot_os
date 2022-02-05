defmodule FarmbotOS.Configurator.RouterTest do
  alias FarmbotOS.Configurator.Router
  alias FarmbotOS.Configurator.ConfigDataLayer

  use ExUnit.Case
  use Plug.Test

  use Mimic
  setup :verify_on_exit!

  import ExUnit.CaptureIO

  @opts Router.init([])
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

  defp get_con(path) do
    conn = conn(:get, path)
    Router.call(conn, @opts)
  end

  @tag :capture_log
  test "index after reset" do
    FarmbotOS.Configurator.ConfigDataLayer
    |> expect(:load_last_reset_reason, fn -> "whoops!" end)

    conn = conn(:get, "/")
    conn = Router.call(conn, @opts)
    assert conn.resp_body =~ "Configure"
    assert conn.resp_body =~ "<div class=\"last-shutdown-reason\">"
    assert conn.resp_body =~ "whoops!"
  end

  @tag :capture_log
  test "redirects" do
    redirects = [
      "/check_network_status.txt",
      "/connecttest.txt",
      "/gen_204",
      "/generate_204",
      "/hotspot-detect.html",
      "/library/test/success.html",
      "/redirect",
      "/setup",
      "/success.txt"
    ]

    Enum.map(redirects, fn path ->
      conn = conn(:get, path)
      conn = Router.call(conn, @opts)
      redir = redirected_to(conn)
      assert redir == "/"
    end)
  end

  @tag :capture_log
  test "celeryscript requests don't get listed as last reset reason" do
    FarmbotOS.Configurator.ConfigDataLayer
    |> expect(:load_last_reset_reason, fn -> "Factory reset requested" end)

    conn = conn(:get, "/")
    conn = Router.call(conn, @opts)
    refute conn.resp_body =~ "Factory reset requested"
  end

  @tag :capture_log
  test "no reset reason" do
    FarmbotOS.Configurator.ConfigDataLayer
    |> expect(:load_last_reset_reason, fn -> nil end)

    conn = conn(:get, "/")
    conn = Router.call(conn, @opts)
    refute conn.resp_body =~ "<div class=\"last-shutdown-reason\">"
  end

  @tag :capture_log
  test "captive portal" do
    conn = conn(:get, "/generate_204")
    conn = Router.call(conn, @opts)
    assert conn.status == 302

    conn = conn(:get, "/gen_204")
    conn = Router.call(conn, @opts)
    assert conn.status == 302
  end

  @tag :capture_log
  test "network index" do
    FarmbotOS.Configurator.FakeNetworkLayer
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

  @tag :capture_log
  test "select network sets session data" do
    conn = conn(:post, "/select_interface")
    conn = Router.call(conn, @opts)
    assert redirected_to(conn) == "/network"

    conn = conn(:post, "/select_interface", %{"interface" => "eth0"})
    conn = Router.call(conn, @opts)
    assert redirected_to(conn) == "/config_wired"
    assert get_session(conn, "ifname") == "eth0"

    conn = conn(:post, "/select_interface", %{"interface" => "wlan0"})
    conn = Router.call(conn, @opts)
    assert redirected_to(conn) == "/config_wireless"
    assert get_session(conn, "ifname") == "wlan0"
  end

  @tag :capture_log
  test "config wired" do
    conn =
      conn(:get, "/config_wired")
      |> init_test_session(%{"ifname" => "eth0"})
      |> Router.call(@opts)

    assert conn.resp_body =~ "Advanced settings"
  end

  @tag :capture_log
  test "config wireless SSID list" do
    FarmbotOS.Configurator.FakeNetworkLayer
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

  @tag :capture_log
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
      conn(:post, "/config_wireless_step_1", %{
        "ssid" => "Test Network",
        "security" => "NONE"
      })
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    refute conn.resp_body =~ "PSK"
    assert conn.resp_body =~ "Advanced settings"

    conn =
      conn(:post, "/config_wireless_step_1", %{
        "ssid" => "Test Network",
        "security" => "WPA-PSK"
      })
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert conn.resp_body =~ "PSK"
    assert conn.resp_body =~ "Advanced settings"

    conn =
      conn(:post, "/config_wireless_step_1", %{
        "ssid" => "Test Network",
        "security" => "WPA2-PSK"
      })
      |> init_test_session(%{"ifname" => "wlan0"})
      |> Router.call(@opts)

    assert conn.resp_body =~ "PSK"
    assert conn.resp_body =~ "Advanced settings"

    conn =
      conn(:post, "/config_wireless_step_1", %{
        "ssid" => "Test Network",
        "security" => "WPA-EAP"
      })
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

  @tag :capture_log
  test "config_network" do
    params = %{
      "dns_name" => "super custom",
      "ntp_server_1" => "pool0.ntpd.org",
      "ntp_server_2" => "pool1.ntpd.org",
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
    assert get_session(conn, "net_config_ssid") == "Test Network"
    assert get_session(conn, "net_config_security") == "WPA-PSK"
    assert get_session(conn, "net_config_psk") == "ABCDEF"

    assert get_session(conn, "net_config_identity") ==
             "NOT TECHNICALLY POSSIBLE"

    assert get_session(conn, "net_config_password") ==
             "NOT TECHNICALLY POSSIBLE"

    assert get_session(conn, "net_config_domain") == "farmbot.org"

    assert get_session(conn, "net_config_name_servers") ==
             "192.168.1.1, 192.168.1.2"

    assert get_session(conn, "net_config_ipv4_method") == "static"
    assert get_session(conn, "net_config_ipv4_address") == "192.168.1.100"
    assert get_session(conn, "net_config_ipv4_gateway") == "192.168.1.1"
    assert get_session(conn, "net_config_ipv4_subnet_mask") == "255.255.0.0"
    assert get_session(conn, "net_config_reg_domain") == "US"
    assert redirected_to(conn) == "/credentials"
  end

  @tag :capture_log
  test "credentials index" do
    FarmbotOS.Configurator.ConfigDataLayer
    |> expect(:load_email, fn -> "test@test.org" end)
    |> expect(:load_password, fn -> "password123" end)
    |> expect(:load_server, fn -> "https://my.farm.bot" end)

    conn = conn(:get, "/credentials") |> Router.call(@opts)
    assert conn.resp_body =~ "test@test.org"
    assert conn.resp_body =~ "password123"
    assert conn.resp_body =~ "https://my.farm.bot"
  end

  @tag :capture_log
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
      conn(:post, "/configure_credentials", %{
        params
        | "server" => "whoops/i/made/a/type"
      })
      |> Router.call(@opts)

    assert redirected_to(conn) == "/credentials"

    conn =
      conn(:post, "/configure_credentials", %{})
      |> Router.call(@opts)

    assert redirected_to(conn) == "/credentials"
  end

  @tag :capture_log
  test "finish" do
    conn =
      conn(:get, "/finish")
      |> Router.call(@opts)

    assert redirected_to(conn) == "/"
  end

  @tag :capture_log
  test "404" do
    conn =
      conn(:get, "/whoops")
      |> Router.call(@opts)

    assert conn.resp_body == "Page not found"
  end

  @tag :capture_log
  test "500" do
    FarmbotOS.Configurator.FakeNetworkLayer
    |> expect(:scan, fn _ ->
      [
        %{
          incorrect: :data
        }
      ]
    end)

    crasher = fn ->
      conn =
        conn(:get, "/config_wireless")
        |> init_test_session(%{"ifname" => "wlan0"})
        |> Router.call(@opts)

      assert conn.status == 500
    end

    assert capture_io(:stderr, crasher) =~ "render error"
  end

  @tag :capture_log
  test "/logger" do
    kon = get_con("/logger")

    words = [
      "DateTime",
      "Function",
      "Level",
      "Message",
      "Module",
      "Src"
    ]

    Enum.map(words, fn word ->
      assert String.contains?(kon.resp_body, word)
    end)
  end

  @tag :capture_log
  test "/api/telemetry/cpu_usage" do
    {:ok, json} = Jason.decode(get_con("/api/telemetry/cpu_usage").resp_body)
    assert Enum.count(json) == 10
    zero = Enum.at(json, 0)
    assert(is_binary(zero["class"]))
    assert(is_binary(zero["timestamp"]))
    assert(is_integer(zero["value"]))
  end

  @tag :capture_log
  test "/finish" do
    expect(ConfigDataLayer, :save_config, 1, fn _conf ->
      :ok
    end)

    # This data would crash in the real app because it is incomplete.
    # Maybe we should add an error handler?
    fake_session = %{
      "ifname" => "MY_IFNAME",
      "auth_config_email" => "MY_EMAIL",
      "auth_config_password" => "MY_PASS",
      "auth_config_server" => "MY_SERVER"
    }

    kon =
      conn(:get, "/finish")
      |> init_test_session(fake_session)
      |> Router.call(@opts)

    assert String.contains?(
             kon.resp_body,
             "If any configuration settings are incorrect, FarmBot will reset"
           )
  end
end
