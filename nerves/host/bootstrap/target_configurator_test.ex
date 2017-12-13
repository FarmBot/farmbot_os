defmodule Farmbot.Host.TargetConfiguratorTest do
  @moduledoc "Routes web connections."

  use Plug.Router

  if Mix.env() == :dev do
    use Plug.Debugger, otp_app: :farmbot
  end

  plug(Plug.Static, from: {:farmbot, "priv/static"}, at: "/")
  plug(Plug.Logger, log: :debug)
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])
  plug(:match)
  plug(:dispatch)

  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage

  @version Mix.Project.config[:version]

  @data_path Application.get_env(:farmbot, :data_path)

  get "/" do
    last_reset_reason_file = Path.join(@data_path, "last_shutdown_reason")
    if File.exists?(last_reset_reason_file) do
      render_page(conn, "index", [version: @version, last_reset_reason: File.read!(last_reset_reason_file)])
    else
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

  get "/firmware" do
    render_page(conn, "firmware")
  end

  get "/credentials" do
    email = ConfigStorage.get_config_value(:string, "authorization", "email") || ""
    pass = ConfigStorage.get_config_value(:string, "authorization", "password") || ""
    server = ConfigStorage.get_config_value(:string, "authorization", "server") || ""
    ConfigStorage.update_config_value(:string, "authorization", "token", nil)
    render_page(conn, "credentials", server: server, email: email, password: pass)
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
