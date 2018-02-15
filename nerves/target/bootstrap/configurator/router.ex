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
  alias Farmbot.System.GlobalConfig

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
    interfaces = get_interfaces()

    info = [
      interfaces: Map.new(interfaces, fn iface ->
        checked = if iface == "wlan0" do
          "checked"
        else
          ""
        end
        if String.first(iface) == "w" do
          {iface, %{type: :wireless, ssids: do_iw_scan(iface), checked: checked}}
        else
          {iface, %{type: :wired, checked: checked}}
        end
      end)
    ]

    render_page(conn, "network", info)
  end

  defp get_interfaces(tries \\ 5)
  defp get_interfaces(0), do: []
  defp get_interfaces(tries) do
    case Nerves.NetworkInterface.interfaces() do
      ["lo"] ->
        Process.sleep(100)
        get_interfaces(tries - 1)
      interfaces when is_list(interfaces) ->
        interfaces
        |> List.delete("usb0") # Delete unusable entries if they exist.
        |> List.delete("lo")
        |> List.delete("sit0")
    end
  end

  defp do_iw_scan(iface) do
    case System.cmd("iw", [iface, "scan", "ap-force"]) do
      {res, 0} -> res |> clean_ssid
      e -> raise "Could not scan for wifi: #{inspect(e)}"
    end
  end

  defp clean_ssid(hc) do
    hc
    |> String.replace("\t", "")
    |> String.replace("\\x00", "")
    |> String.split("\n")
    |> Enum.filter(fn s -> String.contains?(s, "SSID: ") end)
    |> Enum.map(fn z -> String.replace(z, "SSID: ", "") end)
    |> Enum.filter(fn z -> String.length(z) != 0 end)
  end

  get "/credentials" do
    email = ConfigStorage.get_config_value(:string, "authorization", "email") || ""
    pass = ConfigStorage.get_config_value(:string, "authorization", "password") || ""
    server = ConfigStorage.get_config_value(:string, "authorization", "server") || ""
    first_boot = ConfigStorage.get_config_value(:bool, "settings", "first_boot")
    ConfigStorage.update_config_value(:string, "authorization", "token", nil)
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

      :ok = input_network_configs([{interface, settings}])
      redir(conn, "/firmware")
    rescue
      err ->
        Logger.error 1, "Failed too input network config: #{Exception.message(err)}: #{inspect System.stacktrace()}"
        redir(conn, "/network")
    end
  end

  defp input_network_configs([{iface, settings} | rest]) when is_map(settings) and is_binary(iface) do
    if settings["enable"] == "on" do

      case settings["type"] do
        "wireless" ->
          %GlobalConfig.NetworkInterface{
            name: iface,
            type: "wireless",
            ssid: Map.fetch!(settings, "ssid"),
            psk: Map.fetch!(settings, "psk"),
            security: "WPA-PSK",
            ipv4_method: "dhcp"
          }

        "wired" ->
          %GlobalConfig.NetworkInterface{name: iface, type: "wired", ipv4_method: "dhcp"}
      end
      |> ConfigStorage.insert!()
    end

    input_network_configs(rest)
  end

  defp input_network_configs([]) do
    :ok
  end

  get "/firmware" do
    render_page(conn, "firmware")
  end

  post "/configure_firmware" do
    {:ok, _, conn} = read_body(conn)

    case conn.body_params do
      %{"firmware_hardware" => hw} when hw in ["arduino", "farmduino", "farmduino_v14"] ->
        ConfigStorage.update_config_value(:string, "settings", "firmware_hardware", hw)

        if Application.get_env(:farmbot, :behaviour)[:firmware_handler] == Farmbot.Firmware.UartHandler do
          Logger.warn 1, "Updating #{hw} firmware."
          # /shrug?
          Farmbot.Firmware.UartHandler.Update.force_update_firmware(hw)
        end

        redir(conn, "/credentials")

      %{"firmware_hardware" => "custom"} ->
        ConfigStorage.update_config_value(:string, "settings", "firmware_hardware", "custom")
        redir(conn, "/credentials")

      _ ->
        send_resp(conn, 500, "Bad firmware_hardware!")
    end
  end

  post "/configure_credentials" do
    {:ok, _, conn} = read_body(conn)

    case conn.body_params do
      %{"email" => email, "password" => pass, "server" => server} ->
        ConfigStorage.update_config_value(:string, "authorization", "email", email)
        ConfigStorage.update_config_value(:string, "authorization", "password", pass)
        ConfigStorage.update_config_value(:string, "authorization", "server", server)
        ConfigStorage.update_config_value(:string, "authorization", "token", nil)
        redir(conn, "/finish")

      _ ->
        send_resp(conn, 500, "invalid request.")
    end
  end

  get "/finish" do
    email = ConfigStorage.get_config_value(:string, "authorization", "email")
    pass = ConfigStorage.get_config_value(:string, "authorization", "password")
    server = ConfigStorage.get_config_value(:string, "authorization", "server")
    network = !(Enum.empty?(ConfigStorage.all(GlobalConfig.NetworkInterface)))
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
