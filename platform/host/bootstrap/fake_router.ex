defmodule Farmbot.Target.Bootstrap.Configurator.Router do
  @moduledoc "Routes web connections."

  use Plug.Router
  use Plug.Debugger, otp_app: :farmbot
  plug(Plug.Static, from: {:farmbot, "priv/static"}, at: "/")
  plug(Plug.Logger, log: :debug)
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])
  plug(:match)
  plug(:dispatch)

  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage

  defmodule MissingField do
    defexception [:message, :field, :redir]
  end

  File.read!("platform/target/network/network.ex") |> Code.compile_string("platform/target/network/network.ex")
  File.read!("platform/target/network/scan_result.ex") |> Code.compile_string("platform/target/network/scan_result.ex")
  alias Farmbot.Target.Network.ScanResult
  @ssids File.read!("data.txt") |> Base.decode64!() |> :erlang.binary_to_term |> ScanResult.decode() |> ScanResult.sort_results() |> ScanResult.decode_security()

  get "/network" do
    interfaces = [:eth0, :wlan0]
    render_page(conn, "network", [interfaces: interfaces])
  end

  post "select_interface" do
    {:ok, _, conn} = read_body(conn)
    interface = conn.body_params["interface"]
    case interface do
      nil                             -> redir(conn, "/network")
      <<"w", _ ::binary >> = wireless -> redir(conn, "/config_wireless?ifname=#{wireless}")
      wired                           -> redir(conn, "/config_wired?ifname=#{wired}")
    end
  end

  get "/config_wired" do
    try do
      ifname = conn.params["ifname"] || raise(MissingField, field: "ifname", message: "ifname not provided", redir: "/network")
      render_page(conn, "config_wired", [ifname: ifname, advanced_network: advanced_network()])
    rescue
      e in MissingField ->
        Logger.error 1, Exception.message(e)
        redir(conn, e.redir)
    end
  end

  get "/config_wireless" do
    try do
      ifname = conn.params["ifname"] || raise(MissingField, field: "ifname", message: "ifname not provided", redir: "/network")
      render_page(conn, "/config_wiresless_step_1", [ifname: ifname, ssids: @ssids])
    rescue
      e in MissingField -> redir(conn, e.redir)
    end
  end

  post "/config_network" do
    try do
      ifname           = conn.params["ifname"] || raise(MissingField, field: "ifname", message: "ifname not provided", redir: "/network")
      ssid             = conn.params["ssid"]
      security         = conn.params["security"]
      psk              = conn.params["psk"]
      domain           = conn.params["domain"] |> remove_empty_string()
      nameservers      = conn.params["nameservers"] |> remove_empty_string() |> decode_nameservers
      ipv4_method      = conn.params["ipv4_method"]
      ipv4_address     = conn.params["ipv4_address"]
      ipv4_gateway     = conn.params["ipv4_gateway"]
      ipv4_subnet_mask = conn.params["ipv4_subnet_mask"]
      ConfigStorage.input_network_config!(%{
        name: ifname,
        ssid: ssid, security: security, psk: psk,
        type: if(ssid, do: "wireless", else: "wired"),
        domain: domain,
        nameservers: nameservers,
        ipv4_method: ipv4_method,
        ipv4_address: ipv4_address,
        ipv4_gateway: ipv4_gateway,
        ipv4_subnet_mask: ipv4_subnet_mask
      })
      redir(conn, "/firmware")
    rescue
      e in MissingField ->
        Logger.error 1, Exception.message(e)
        redir(conn, e.redir)
    end
  end

  post "select_ssid" do
    try do
      ifname = conn.params["ifname"]     || raise(MissingField, field: "ifname",   message: "ifname not provided",   redir: "/network")
      ssid   = conn.params["ssid"]       || raise(MissingField, field: "ssid",     message: "ssid not provided",     redir: "/config_wireless?ifname=#{ifname}")
      security = conn.params["security"] || raise(MissingField, field: "security", message: "security not provided", redir: "/config_wireless?ifname=#{ifname}")
      case security do
        "WPA-PSK" ->  render_page(conn, "/config_wiresless_step_2_PSK",   [ssid: ssid, ifname: ifname, security: security, advanced_network: advanced_network()])
        "WPA2-PSK" -> render_page(conn, "/config_wiresless_step_2_PSK",   [ssid: ssid, ifname: ifname, security: security, advanced_network: advanced_network()])
        "NONE" ->     render_page(conn, "/config_wiresless_step_2_NONE",  [ssid: ssid, ifname: ifname, security: security, advanced_network: advanced_network()])
        _other ->     render_page(conn, "/config_wiresless_step_2_other", [ssid: ssid, ifname: ifname, security: security, advanced_network: advanced_network()])
      end
    rescue
      e in MissingField ->
        Logger.error 1, Exception.message(e)
        redir(conn, e.redir)
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
    |> EEx.eval_file(info)
    |> (fn contents -> send_resp(conn, 200, contents) end).()
  end

  defp template_file(file) do
    "#{:code.priv_dir(:farmbot)}/static/templates/#{file}.html.eex"
  end

  defp remove_empty_string(""), do: nil
  defp remove_empty_string(str), do: str
  defp decode_nameservers(nil), do: nil
  defp decode_nameservers(str), do: String.split(str, " ")

  defp advanced_network do
    template_file("advanced_network") |> EEx.eval_file([])
  end
end
