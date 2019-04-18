defmodule FarmbotOS.Platform.Target.Configurator.Router do
  @moduledoc "Routes web connections."

  use Plug.Router
  use Plug.Debugger, otp_app: :farmbot
  plug(Plug.Static, from: {:farmbot, "priv/static"}, at: "/")
  plug(Plug.Logger, log: :debug)
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])
  plug(:match)
  plug(:dispatch)

  require FarmbotCore.Logger
  import Phoenix.HTML
  alias FarmbotCore.Config
  alias FarmbotOS.Platform.Target.Network

  import Config,
    only: [
      get_config_value: 3,
      update_config_value: 4
    ]

  defmodule MissingField do
    defexception [:message, :field, :redir]
  end

  @version FarmbotCore.Project.version()
  @data_path FarmbotOS.FileSystem.data_path()

  get "/generate_204" do
    send_resp(conn, 204, "")
  end

  get "/gen_204" do
    send_resp(conn, 204, "")
  end

  get "/" do
    last_reset_reason_file = Path.join(@data_path, "last_shutdown_reason")

    case File.read(last_reset_reason_file) do
      {:ok, reason} when is_binary(reason) ->
        if String.contains?(reason, "CeleryScript request.") do
          render_page(conn, "index", version: @version, last_reset_reason: nil)
        else
          render_page(conn, "index",
            version: @version,
            last_reset_reason: Phoenix.HTML.raw(reason)
          )
        end

      {:error, _} ->
        render_page(conn, "index", version: @version, last_reset_reason: nil)
    end
  end

  get "/view_logs" do
    all_logs = LoggerBackendSqlite.all_logs()
    render_page(conn, "view_logs", logs: all_logs)
  end

  get "/logs" do
    file = Path.join(@data_path, "debug_logs.sqlite3")

    case File.read(file) do
      {:ok, data} ->
        md5 = data |> :erlang.md5() |> Base.encode16()

        conn
        |> put_resp_content_type("application/octet-stream")
        |> put_resp_header(
          "Content-Disposition",
          "inline; filename=\"#{@version}-#{md5}-logs.sqlite3\""
        )
        |> send_resp(200, data)

      {:error, posix} ->
        send_resp(conn, 404, "Error downloading file: #{posix}")
    end
  end

  get("/setup", do: redir(conn, "/"))

  # NETWORKCONFIG
  get "/network" do
    interfaces = Network.list_interfaces()
    render_page(conn, "network", interfaces: interfaces, post_action: "select_interface")
  end

  post "select_interface" do
    {:ok, _, conn} = read_body(conn)
    interface = conn.body_params["interface"] |> remove_empty_string()

    case interface do
      nil -> redir(conn, "/network")
      <<"w", _::binary>> = wireless -> redir(conn, "/config_wireless?ifname=#{wireless}")
      wired -> redir(conn, "/config_wired?ifname=#{wired}")
    end
  end

  get "/config_wired" do
    try do
      ifname =
        conn.params["ifname"] ||
          raise(MissingField, field: "ifname", message: "ifname not provided", redir: "/network")

      render_page(conn, "config_wired", ifname: ifname, advanced_network: advanced_network())
    rescue
      e in MissingField ->
        FarmbotCore.Logger.error(1, Exception.message(e))
        redir(conn, e.redir)
    end
  end

  get "/config_wireless" do
    try do
      ifname =
        conn.params["ifname"] ||
          raise(MissingField, field: "ifname", message: "ifname not provided", redir: "/network")

      opts = [
        ifname: ifname,
        ssids: Network.Utils.scan(ifname),
        post_action: "config_wireless_step_1"
      ]

      render_page(conn, "/config_wireless_step_1", opts)
    rescue
      e in MissingField -> redir(conn, e.redir)
    end
  end

  post "config_wireless_step_1" do
    try do
      ifname =
        conn.params["ifname"] |> remove_empty_string() ||
          raise(MissingField, field: "ifname", message: "ifname not provided", redir: "/network")

      ssid = conn.params["ssid"] |> remove_empty_string()
      security = conn.params["security"] |> remove_empty_string()
      manualssid = conn.params["manualssid"] |> remove_empty_string()

      opts = [
        ssid: ssid,
        ifname: ifname,
        security: security,
        advanced_network: advanced_network(),
        post_action: "config_network"
      ]

      cond do
        manualssid != nil ->
          render_page(
            conn,
            "/config_wireless_step_2_custom",
            Keyword.put(opts, :ssid, manualssid)
          )

        ssid == nil ->
          raise(MissingField,
            field: "ssid",
            message: "ssid not provided",
            redir: "/config_wireless?ifname=#{ifname}"
          )

        security == nil ->
          raise(MissingField,
            field: "security",
            message: "security not provided",
            redir: "/config_wireless?ifname=#{ifname}"
          )

        security == "WPA-PSK" ->
          render_page(conn, "/config_wireless_step_2_PSK", opts)

        security == "WPA-PSK" ->
          render_page(conn, "/config_wireless_step_2_PSK", opts)

        security == "NONE" ->
          render_page(conn, "/config_wireless_step_2_NONE", opts)

        true ->
          render_page(conn, "/config_wireless_step_2_other", opts)
      end
    rescue
      e in MissingField ->
        FarmbotCore.Logger.error(1, Exception.message(e))
        redir(conn, e.redir)
    end
  end

  post "/config_network" do
    try do
      ifname =
        conn.params["ifname"] ||
          raise(MissingField, field: "ifname", message: "ifname not provided", redir: "/network")

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

      dns_name = conn.params["dns_name"] |> remove_empty_string()
      ntp_server_1 = conn.params["ntp_server_1"] |> remove_empty_string()
      ntp_server_2 = conn.params["ntp_server_2"] |> remove_empty_string()

      reg_domain = conn.params["regulatory_domain"] |> remove_empty_string()

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

      type = if(ssid, do: "wireless", else: "wired")

      old =
        Config.Repo.get_by(Config.NetworkInterface, name: ifname) || %Config.NetworkInterface{}

      changeset =
        Config.NetworkInterface.changeset(old, %{
          name: ifname,
          ssid: ssid,
          security: security,
          psk: psk,
          type: type,
          domain: domain,
          identity: identity,
          password: password,
          name_servers: name_servers,
          ipv4_method: ipv4_method,
          ipv4_address: ipv4_address,
          ipv4_gateway: ipv4_gateway,
          ipv4_subnet_mask: ipv4_subnet_mask,
          regulatory_domain: reg_domain
        })

      case Config.Repo.insert_or_update(changeset) do
        {:ok, _} ->
          redir(conn, "/firmware")

        {:error, %{errors: r}} when type == "wireless" ->
          FarmbotCore.Logger.error(1, "Network error: #{inspect(r)}")
          redir(conn, "/config_wireless?ifname=#{ifname}")

        {:error, %{errors: r}} when type == "wired" ->
          FarmbotCore.Logger.error(1, "Network error: #{inspect(r)}")
          redir(conn, "/config_wired?ifname=#{ifname}")
      end
    rescue
      e in MissingField ->
        FarmbotCore.Logger.error(1, Exception.message(e))
        redir(conn, e.redir)
    end
  end

  # /NETWORKCONFIG

  get "/firmware" do
    redir(conn, "/credentials")
  end

  get "/credentials" do
    email = get_config_value(:string, "authorization", "email") || ""
    pass = get_config_value(:string, "authorization", "password") || ""
    server = get_config_value(:string, "authorization", "server") || ""
    update_config_value(:string, "authorization", "token", nil)

    render_page(conn, "credentials",
      server: server,
      email: email,
      password: pass
    )
  end

  post "/configure_credentials" do
    {:ok, _, conn} = read_body(conn)

    case conn.body_params do
      %{"email" => email, "password" => pass, "server" => server} ->
        if server = test_uri(server) do
          Logger.info("server valid: #{server}")
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
    network = !Enum.empty?(Config.get_all_network_configs())

    if email && pass && server && network do
      Network.reload()
      render_page(conn, "finish")
    else
      FarmbotCore.Logger.warn(3, "Not configured yet. Restarting configuration.")
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
    |> EEx.eval_file(info, engine: Phoenix.HTML.Engine)
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
      when scheme in ["https", "http"] and is_binary(host) and is_integer(port) ->
        uri

      _ ->
        Logger.error("#{inspect(uri)} is not valid")
        nil
    end
  end
end
