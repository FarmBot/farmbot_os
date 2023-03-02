defmodule FarmbotOS.Configurator.Router do
  @moduledoc "Routes web connections for configuring farmbot os"

  require FarmbotOS.Logger
  require Logger
  require FarmbotTelemetry

  import Phoenix.HTML
  use Plug.Router
  use Plug.Debugger, otp_app: :farmbot
  alias FarmbotOS.Configurator.ConfigDataLayer

  plug(Plug.Logger)
  plug(Plug.Static, from: {:farmbot, "priv/static"}, at: "/")
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(Plug.Session,
    store: :ets,
    key: "_farmbot_session",
    table: :configurator_session
  )

  plug(:fetch_session)
  plug(:match)
  plug(:dispatch)

  @network_layer Application.get_env(:farmbot, FarmbotOS.Configurator)[
                   :network_layer
                 ]
  @telemetry_layer FarmbotOS.Configurator.DetsTelemetryLayer

  # Trigger for captive portal for various operating systems
  get("/gen_204", do: redir(conn, "/"))
  get("/generate_204", do: redir(conn, "/"))
  get("/hotspot-detect.html", do: redir(conn, "/"))
  get("/library/test/success.html", do: redir(conn, "/"))
  get("/connecttest.txt", do: redir(conn, "/"))
  get("/redirect", do: redir(conn, "/"))
  get("/check_network_status.txt", do: redir(conn, "/"))
  get("/success.txt", do: redir(conn, "/"))

  get "/logger" do
    render_page(conn, "logger")
  end

  get "/api/telemetry/cpu_usage" do
    render_json(conn, cpu_usage())
  end

  get "/" do
    FarmbotTelemetry.event(:configurator, :configuration_start)

    redir(conn, "/network")
  end

  get("/setup", do: redir(conn, "/"))

  # NETWORKCONFIG
  get "/network" do
    interfaces = list_interfaces()

    case interfaces do
      [{<<"w", _::binary>> = ifname, _}] ->
        conn
        |> put_session("iftype", "wireless")
        |> put_session("ifname", ifname)
        |> redir("/config_wireless")

      [{ifname, _}] ->
        conn
        |> put_session("iftype", "wired")
        |> put_session("ifname", ifname)
        |> redir("/config_wired")

      _ ->
        render_page(conn, "network",
          interfaces: interfaces,
          post_action: "select_interface",
          subtitle: subtitle(),
          last_reset_reason: load_last_reset_reason()
        )
    end
  end

  post "select_interface" do
    {:ok, _, conn} = read_body(conn)
    ifname = conn.body_params["interface"] |> remove_empty_string()

    case ifname do
      nil ->
        redir(conn, "/network")

      <<"w", _::binary>> ->
        conn
        |> put_session("iftype", "wireless")
        |> put_session("ifname", ifname)
        |> redir("/config_wireless")

      _ ->
        conn
        |> put_session("iftype", "wired")
        |> put_session("ifname", ifname)
        |> redir("/config_wired")
    end
  end

  get "/config_wired" do
    ifname = get_session(conn, "ifname")

    render_page(conn, "config_wired",
      ifname: ifname,
      advanced_network: advanced_network(),
      subtitle: subtitle()
    )
  end

  get "/config_wireless" do
    ifname = get_session(conn, "ifname")

    render_page(conn, "/config_wireless_step_1",
      ifname: ifname,
      ssids: scan(ifname),
      post_action: "config_wireless_step_1",
      subtitle: subtitle()
    )
  end

  post "config_wireless_step_1" do
    ifname = get_session(conn, "ifname")
    ssid = conn.params["ssid"] |> remove_empty_string()
    security = conn.params["security"] |> remove_empty_string()
    manualssid = conn.params["manualssid"] |> remove_empty_string()

    opts = [
      ssid: ssid,
      ifname: ifname,
      security: security,
      advanced_network: advanced_network(),
      post_action: "config_network",
      subtitle: subtitle()
    ]

    cond do
      manualssid != nil ->
        render_page(
          conn,
          "/config_wireless_step_2_custom",
          Keyword.put(opts, :ssid, manualssid)
        )

      ssid == nil ->
        redir(conn, "/config_wireless")

      security == nil ->
        redir(conn, "/config_wireless")

      security == "WPA-PSK" ->
        render_page(conn, "/config_wireless_step_2_PSK", opts)

      security == "WPA2-PSK" ->
        render_page(conn, "/config_wireless_step_2_PSK", opts)

      security == "WPA-EAP" ->
        render_page(conn, "/config_wireless_step_2_EAP", opts)

      security == "NONE" ->
        render_page(conn, "/config_wireless_step_2_NONE", opts)

      true ->
        render_page(conn, "/config_wireless_step_2_other", opts)
    end
  end

  post "/config_network" do
    # Global configuration data
    dns_name = conn.params["dns_name"] |> remove_empty_string()
    ntp1 = conn.params["ntp_server_1"] |> remove_empty_string()
    ntp2 = conn.params["ntp_server_2"] |> remove_empty_string()

    # Network Interface configuration data
    ssid = conn.params["ssid"] |> remove_empty_string()
    security = conn.params["security"] |> remove_empty_string()
    psk = conn.params["psk"] |> remove_empty_string()
    identity = conn.params["identity"] |> remove_empty_string()
    password = conn.params["password"] |> remove_empty_string()
    domain = conn.params["domain"] |> remove_empty_string()
    name_servers = conn.params["name_servers"] |> remove_empty_string()
    ipv4_method = conn.params["ipv4_method"] |> remove_empty_string()
    ipv4_address = conn.params["ipv4_address"] |> remove_empty_string()
    ipv4_gateway = conn.params["ipv4_gateway"] |> remove_empty_string()
    ipv4_subnet_mask = conn.params["ipv4_subnet_mask"] |> remove_empty_string()
    reg_domain = conn.params["regulatory_domain"] |> remove_empty_string()

    conn
    |> put_session("net_config_dns_name", dns_name)
    |> put_session("net_config_ntp1", ntp1)
    |> put_session("net_config_ntp2", ntp2)
    |> put_session("net_config_ssid", ssid)
    |> put_session("net_config_security", security)
    |> put_session("net_config_psk", psk)
    |> put_session("net_config_identity", identity)
    |> put_session("net_config_password", password)
    |> put_session("net_config_domain", domain)
    |> put_session("net_config_name_servers", name_servers)
    |> put_session("net_config_ipv4_method", ipv4_method)
    |> put_session("net_config_ipv4_address", ipv4_address)
    |> put_session("net_config_ipv4_gateway", ipv4_gateway)
    |> put_session("net_config_ipv4_subnet_mask", ipv4_subnet_mask)
    |> put_session("net_config_reg_domain", reg_domain)
    |> redir("/credentials")
  end

  # /NETWORKCONFIG

  get "/credentials" do
    email = get_session(conn, "auth_config_email") || load_email() || ""
    pass = get_session(conn, "auth_config_password") || load_password() || ""
    server = get_session(conn, "auth_config_server") || load_server() || ""

    render_page(conn, "credentials",
      server: server,
      email: email,
      password: pass,
      subtitle: subtitle()
    )
  end

  post "/configure_credentials" do
    {:ok, _, conn} = read_body(conn)

    case conn.body_params do
      %{"email" => email, "password" => pass, "server" => server} ->
        if server = test_uri(server) do
          Logger.info("server valid: #{server}")

          conn
          |> put_session("auth_config_email", email)
          |> put_session("auth_config_password", pass)
          |> put_session("auth_config_server", server)
          |> redir("/finish")
        else
          conn
          |> put_session("__error", "Server is not a valid URI")
          |> redir("/credentials")
        end

      _ ->
        conn
        |> put_session(
          "__error",
          "Email, Server, or Password are missing or invalid"
        )
        |> redir("/credentials")
    end
  end

  get "/finish" do
    FarmbotOS.Logger.debug(1, "Configuration complete")

    # TODO(Rick): This pattern match is not 100% accurate.
    # TO see what I mean, try calling `save_config/1` with
    # _only_ the parameters provided in the line below-
    # it will crash as it is missing numerous keys.
    # It might be good to add an error page or something.
    case get_session(conn) do
      %{
        "ifname" => _,
        "auth_config_email" => _,
        "auth_config_password" => _,
        "auth_config_server" => _
      } ->
        FarmbotOS.Logger.debug(1, "Configuration success!")
        save_config(get_session(conn))

        render_page(conn, "finish",
          subtitle: subtitle(),
          target: target()
        )

      _ ->
        FarmbotOS.Logger.debug(1, "Configuration FAIL")
        redir(conn, "/")
    end
  end

  match(_, do: send_resp(conn, 404, "Page not found"))

  defp redir(conn, loc) do
    conn
    |> put_resp_header("location", loc)
    |> send_resp(302, loc)
  end

  defp render_page(conn, page, info \\ []) do
    page
    |> template_file()
    |> EEx.eval_file(Keyword.merge([version: version()], info),
      engine: Phoenix.HTML.Engine
    )
    |> (fn {:safe, contents} -> send_resp(conn, 200, contents) end).()
  rescue
    e ->
      IO.warn("render error", __STACKTRACE__)

      send_resp(
        conn,
        500,
        "Failed to render page: #{page} error: #{Exception.message(e)}"
      )
  end

  defp render_json(conn, data) do
    conn = put_resp_header(conn, "content-type", "application/json")

    case FarmbotOS.JSON.encode(data) do
      {:ok, json} ->
        send_resp(conn, 200, json)

      _ ->
        send_resp(
          conn,
          501,
          FarmbotOS.JSON.encode!(%{error: "failed to render json"})
        )
    end
  end

  defp template_file(file) do
    "#{:code.priv_dir(:farmbot)}/static/templates/#{file}.html.eex"
  end

  defp remove_empty_string(""), do: nil
  defp remove_empty_string(str), do: str

  defp advanced_network do
    template_file("advanced_network")
    |> EEx.eval_file([])
    |> raw()
  end

  defp test_uri(nil), do: nil

  defp test_uri(uri) do
    case URI.parse(uri) do
      %URI{host: host, port: port, scheme: scheme}
      when scheme in ["https", "http"] and is_binary(host) and is_integer(port) ->
        uri

      _ ->
        FarmbotOS.Logger.error(1, "#{inspect(uri)} is not valid")
        nil
    end
  end

  defp load_last_reset_reason do
    ConfigDataLayer.load_last_reset_reason()
  end

  defp load_email do
    ConfigDataLayer.load_email()
  end

  defp load_password do
    ConfigDataLayer.load_password()
  end

  def load_server do
    ConfigDataLayer.load_server()
  end

  defp save_config(conf) do
    ConfigDataLayer.save_config(conf)
  end

  defp list_interfaces() do
    @network_layer.list_interfaces()
  end

  defp scan(interface) do
    @network_layer.scan(interface)
  end

  ## Telemetry layer calls

  defp cpu_usage() do
    @telemetry_layer.cpu_usage()
  end

  defp version, do: FarmbotOS.Project.version()
  defp target, do: FarmbotOS.Project.target()

  defp subtitle() do
    device =
      %{
        host: "Computer",
        rpi4: "Raspberry Pi 4",
        rpi3: "Raspberry Pi 3 and Zero 2 W",
        rpi: "Raspberry Pi Zero W"
      }[target()]

    "v#{version()} for #{device}"
  end
end
