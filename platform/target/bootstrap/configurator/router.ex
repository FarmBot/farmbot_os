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
  import Phoenix.HTML
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [
    get_config_value: 3,
    update_config_value: 4
  ]

  defmodule MissingField do
    defexception [:message, :field, :redir]
  end

  @version Farmbot.Project.version()
  @data_path Application.get_env(:farmbot, :data_path)

  get "/" do
    last_reset_reason_file = Path.join(@data_path, "last_shutdown_reason")
    case File.read(last_reset_reason_file) do
      {:ok, reason} when is_binary(reason) ->
        if String.contains?(reason, "CeleryScript request.") do
          render_page(conn, "index", [version: @version, last_reset_reason: nil])
        else
          render_page(conn, "index", [version: @version, last_reset_reason: Phoenix.HTML.raw(reason)])
        end
      {:error, _} ->
        render_page(conn, "index", [version: @version, last_reset_reason: nil])
    end
  end

  get "/view_logs" do
    all_logs = LoggerBackendEcto.all_logs()
    render_page(conn, "view_logs", [logs: all_logs])
  end

  get "/logs" do
    file = Path.join(@data_path, "debug_logs.sqlite3")
    case File.read(file) do
      {:ok, data} ->
        md5 = data |> :erlang.md5() |> Base.encode16()
        conn
        |> put_resp_content_type("application/octet-stream")
        |> put_resp_header("Content-Disposition", "inline; filename=\"#{@version}-#{md5}-logs.sqlite3\"")
        |> send_resp(200, data)
      {:error, posix} ->
        send_resp(conn, 404, "Error downloading file: #{posix}")
    end
  end

  get "/setup", do: redir(conn, "/")

#NETWORKCONFIG
  get "/network" do
    interfaces = Farmbot.Target.Network.get_interfaces()
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
      opts = [ifname: ifname, ssids: Farmbot.Target.Network.scan(ifname), post_action: "config_wireless_step_1"]
      render_page(conn, "/config_wireless_step_1", opts)
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

      dns_name         = conn.params["dns_name"] |> remove_empty_string()
      ntp_server_1     = conn.params["ntp_server_1"] |> remove_empty_string()
      ntp_server_2     = conn.params["ntp_server_2"] |> remove_empty_string()

      ssh_key = conn.params["ssh_key"] |> remove_empty_string()

      if dns_name do
        update_config_value(:string, "settings", "default_dns_name", dns_name)
      end

      if ntp_server_1 do
        update_config_value(:string, "settings", "default_ntp_server_1", ntp_server_1)
      end

      if ntp_server_2 do
        update_config_value(:string, "settings", "default_ntp_server_2", ntp_server_2)
      end

      if ssh_key do
        update_config_value(:string, "settings", "authorized_ssh_key", ssh_key)
      end

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
#/NETWORKCONFIG

  get "/credentials" do
    email = get_config_value(:string, "authorization", "email") || ""
    pass = get_config_value(:string, "authorization", "password") || ""
    server = get_config_value(:string, "authorization", "server") || ""
    first_boot = get_config_value(:bool, "settings", "first_boot")
    update_config_value(:string, "authorization", "token", nil)
    render_page(conn, "credentials", server: server, email: email, password: pass, first_boot: first_boot)
  end

  get "/firmware" do
    render_page(conn, "firmware")
  end

  post "/configure_firmware" do
    {:ok, _, conn} = read_body(conn)

    case conn.body_params do
      %{"firmware_hardware" => hw} when hw in ["arduino", "farmduino", "farmduino_k14"] ->
        update_config_value(:string, "settings", "firmware_hardware", hw)

        if Application.get_env(:farmbot, :behaviour)[:firmware_handler] == Farmbot.Firmware.UartHandler do
          Logger.warn 1, "Updating #{hw} firmware."
          # /shrug?
          Farmbot.Firmware.UartHandler.Update.force_update_firmware(hw)
        end

        redir(conn, "/credentials")

      %{"firmware_hardware" => "custom"} ->
        update_config_value(:string, "settings", "firmware_hardware", "custom")
        redir(conn, "/credentials")

      _ ->
        send_resp(conn, 500, "Bad firmware_hardware!")
    end
  end

  post "/configure_credentials" do
    {:ok, _, conn} = read_body(conn)

    case conn.body_params do
      %{"email" => email, "password" => pass, "server" => server} ->
        if server = test_uri(server) do
          IO.puts "server valid: #{server}"
        else
          send_resp(conn, 500, "server field invalid")
        end
        update_config_value(:string, "authorization", "email", email)
        update_config_value(:string, "authorization", "password", pass)
        update_config_value(:string, "authorization", "server", server)
        update_config_value(:string, "authorization", "token", nil)
        redir(conn, "/finish")

      _ ->
        send_resp(conn, 500, "invalid request.")
    end
  end

  get "/finish" do
    email = get_config_value(:string, "authorization", "email")
    pass = get_config_value(:string, "authorization", "password")
    server = get_config_value(:string, "authorization", "server")
    network = !(Enum.empty?(ConfigStorage.get_all_network_configs()))
    if email && pass && server && network do
      conn = render_page(conn, "finish")
      spawn fn() ->
        try do
          alias Farmbot.Target.Bootstrap.Configurator
          Logger.success 2, "Configuration finished."
          Process.sleep(2500) # Allow the page to render and send.
          :ok = GenServer.stop(Configurator.CaptivePortal, :normal)
          # :ok = Supervisor.terminate_child(Configurator, Configurator.CaptivePortal)
          :ok = Supervisor.stop(Configurator)
          Process.sleep(2500) # Good luck.
        rescue
          e ->
            Logger.warn 1, "Falied to close captive portal. Good luck. " <>
              Exception.message(e)
        end
      end
      conn
    else
      Logger.warn 3, "Not configured yet. Restarting configuration."
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
    |> EEx.eval_file(info, [engine: Phoenix.HTML.Engine])
    |> (fn {:safe, contents} -> send_resp(conn, 200, contents) end).()
  rescue
    e -> send_resp(conn, 500, "Failed to render page: #{page} inspect: #{Exception.message(e)}")
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
        when scheme in ["https", "http"]
        and is_binary(host)
        and is_integer(port) -> uri
      _ ->
        IO.puts "#{inspect uri} is not valid"
        nil
    end
  end
end
