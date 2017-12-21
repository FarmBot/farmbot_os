defmodule Farmbot.Host.TargetConfiguratorTest do
  @moduledoc "Routes web connections."

  use Plug.Router

  if Farmbot.Project.env() == :dev do
    use Plug.Debugger, otp_app: :farmbot
  end

  plug(Plug.Static, from: {:farmbot, "priv/static"}, at: "/")
  plug(Plug.Logger, log: :debug)
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])
  plug(:match)
  plug(:dispatch)

  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage

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

  get "/setup" do
    last_reset_reason_file = Path.join(@data_path, "last_shutdown_reason")
    if File.exists?(last_reset_reason_file) do
      render_page(conn, "index", [version: @version, last_reset_reason: File.read!(last_reset_reason_file)])
    else
      render_page(conn, "index", [version: @version, last_reset_reason: nil])
    end
  end

  get "/network" do
    render_page(conn, "network", interfaces: [
      {"fake_wireless_iface0", %{type: :wireless, ssids: ["not", "a", "real", "ssid", "list"], checked: "checked"}},
      {"fake_wired_iface1", %{type: :wired, checked: nil}}
    ])
  end

  post "/configure_network" do
    interface = conn.body_params["interface"]
    settings =
      Enum.filter(conn.body_params, &String.starts_with?(elem(&1, 0), interface))
      |> Enum.map(fn({key, val}) -> {String.trim(key, interface <> "_"), val} end)
      |> Map.new()
      |> Map.put("enable", "on")
    Logger.info 1, "Got fake network config interface: `#{interface}` settings: #{inspect settings}"
    redir(conn, "/credentials")
  end

  get "/firmware" do
    render_page(conn, "firmware")
  end

  post "/configure_firmware" do
    body_params = conn.body_params
    if match?(%{"firmware_hardware" => hw} when hw in ["arduino", "farmduino"], body_params) do
      redir(conn, "/credentials")
    else
      send_resp(conn, 500, "#{inspect body_params} is invalid configuration for `configure_firmware`")
    end
  end

  get "/credentials" do
    email = ConfigStorage.get_config_value(:string, "authorization", "email") || ""
    pass = ConfigStorage.get_config_value(:string, "authorization", "password") || ""
    server = ConfigStorage.get_config_value(:string, "authorization", "server") || ""
    first_boot = ConfigStorage.get_config_value(:bool, "settings", "first_boot")
    ConfigStorage.update_config_value(:string, "authorization", "token", nil)
    render_page(conn, "credentials", server: server, email: email, password: pass, first_boot: first_boot)
  end

  get "/finish" do
    send_resp(conn, 200, "bye")
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
