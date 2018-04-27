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
  import ConfigStorage, only: [
    get_config_value: 3,
    update_config_value: 4
  ]

  @version Farmbot.Project.version()
  @data_path Application.get_env(:farmbot, :data_path)

  get "/" do
    last_reset_reason_file = Path.join(@data_path, "last_shutdown_reason")
    case File.read(last_reset_reason_file) do
      {:ok, reason} when is_binary(reason) ->
        if String.contains?(reason, "CeleryScript request.") do
          render_page(conn, "index", [version: @version, last_reset_reason: nil])
        else
          render_page(conn, "index", [version: @version, last_reset_reason: reason])
        end
      {:error, _} ->
        render_page(conn, "index", [version: @version, last_reset_reason: nil])
    end
  end

  get "/setup", do: redir(conn, "/")

  get "/network" do
    interfaces = Farmbot.Target.Network.get_interfaces()
    Map.new(interfaces, fn(ifname) ->
      # This is probably a not so good idea, but
      # Not really a problem for rpiX.
      if String.contains?(ifname, "w") do
        {iface, %{type: :wireless, ssids: Farmbot.Target.Network.do_scan(iface), enabled: true}}
      else
        {iface, %{type: :wired, ssids: [], enabled: false}}
      end
    end)

    render_page(conn, "network", info)
  end

  get "/credentials" do
    email = get_config_value(:string, "authorization", "email") || ""
    pass = get_config_value(:string, "authorization", "password") || ""
    server = get_config_value(:string, "authorization", "server") || ""
    first_boot = get_config_value(:bool, "settings", "first_boot")
    update_config_value(:string, "authorization", "token", nil)
    render_page(conn, "credentials", server: server, email: email, password: pass, first_boot: first_boot)
  end

  post "/configure_network" do
    try do
      {:ok, _, conn} = read_body(conn)
      interface = conn.body_params["interface"]
      settings =
        Enum.filter(conn.body_params, &String.starts_with?(elem(&1, 0), interface))
        |> Enum.map(fn({key, val}) -> {String.trim(key, interface <> "_"), val} end)
        |> Map.new()
        |> Map.put("enable", "on")

      :ok = ConfigStorage.input_network_configs([{interface, settings}])
      redir(conn, "/firmware")
    rescue
      err ->
        Logger.error 1, "Failed too input network config: #{Exception.message(err)}: #{inspect System.stacktrace()}"
        ConfigStorage.destroy_all_network_configs()
        redir(conn, "/network")
    end
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
          :ok = Supervisor.terminate_child(Configurator, Configurator.CaptivePortal)
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
    |> EEx.eval_file(info)
    |> (fn contents -> send_resp(conn, 200, contents) end).()
  rescue
    e -> send_resp(conn, 500, "Failed to render page: #{page} inspect: #{Exception.message(e)}")
  end

  defp template_file(file) do
    "#{:code.priv_dir(:farmbot)}/static/templates/#{file}.html.eex"
  end
end
