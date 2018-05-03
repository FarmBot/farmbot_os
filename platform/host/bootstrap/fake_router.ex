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
    render_page(conn, "network", [interfaces: interfaces, post_action: "select_interface"])
  end

  post "select_interface" do
    {:ok, _, conn} = read_body(conn)
    interface = conn.body_params["interface"] |> remove_empty_string()
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
      render_page(conn, "/config_wireless_step_1", [ifname: ifname, ssids: @ssids, post_action: "config_wireless_step_1"])
    rescue
      e in MissingField -> redir(conn, e.redir)
    end
  end

  post "config_wireless_step_1" do
    try do
      ifname = conn.params["ifname"]   |> remove_empty_string()   || raise(MissingField, field: "ifname",   message: "ifname not provided",   redir: "/network")
      ssid   = conn.params["ssid"] |> remove_empty_string()
      security = conn.params["security"] |> remove_empty_string()
      manualssid = conn.params["manualssid"] |> remove_empty_string()
      opts = [ssid: ssid, ifname: ifname, security: security, advanced_network: advanced_network(), post_action: "config_network"]
      cond do
        manualssid != nil      -> render_page(conn, "/config_wireless_step_2_custom", Keyword.put(opts, :ssid, manualssid))
        ssid == nil -> raise(MissingField, field: "ssid",     message: "ssid not provided",     redir: "/config_wireless?ifname=#{ifname}")
        security == nil ->  raise(MissingField, field: "security", message: "security not provided", redir: "/config_wireless?ifname=#{ifname}")
        security == "WPA-PSK"  -> render_page(conn, "/config_wireless_step_2_PSK",    opts)
        security == "NONE"     -> render_page(conn, "/config_wireless_step_2_NONE",   opts)
        true                   -> render_page(conn, "/config_wireless_step_2_other",  opts)
      end
    rescue
      e in MissingField ->
        Logger.error 1, Exception.message(e)
        redir(conn, e.redir)
    end
  end

  post "/config_network" do
    try do
      ifname           = conn.params["ifname"] || raise(MissingField, field: "ifname", message: "ifname not provided", redir: "/network")
      ssid             = conn.params["ssid"] |> remove_empty_string()
      security         = conn.params["security"] |> remove_empty_string()
      psk              = conn.params["psk"] |> remove_empty_string()
      domain           = conn.params["domain"] |> remove_empty_string()
      name_servers      = conn.params["name_servers"] |> remove_empty_string()
      ipv4_method      = conn.params["ipv4_method"] |> remove_empty_string()
      ipv4_address     = conn.params["ipv4_address"] |> remove_empty_string()
      ipv4_gateway     = conn.params["ipv4_gateway"] |> remove_empty_string()
      ipv4_subnet_mask = conn.params["ipv4_subnet_mask"] |> remove_empty_string()
      ConfigStorage.input_network_config!(%{
        name: ifname,
        ssid: ssid, security: security, psk: psk,
        type: if(ssid, do: "wireless", else: "wired"),
        domain: domain,
        name_servers: name_servers,
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

  defp advanced_network do
    template_file("advanced_network") |> EEx.eval_file([])
  end
end
