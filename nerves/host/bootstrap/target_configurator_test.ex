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

  require Logger
  alias Farmbot.System.ConfigStorage

  get "/" do
    last_reset_reason =
      ConfigStorage.get_config_value(:string, "authorization", "last_shutdown_reason") || ""

    render_page(conn, "index", last_reset_reason: last_reset_reason)
  end

  get "/network" do
    render_page(conn, "network", [interfaces: []])
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

  post "/configure_network" do
    redir(conn, "/firmware")
  end

  get "/finish" do
    Logger.info("Configuration finished.")
    render_page(conn, "finish")
  end

  post "/configure_firmware" do
    {:ok, _, conn} = read_body(conn)

    case conn.body_params do
      %{"firmware_hardware" => hw} when hw in ["arduino", "farmduino"] ->
        ConfigStorage.update_config_value(:string, "hardware", "firmware_hardware", hw)
        # TODO Flash firmware here.
        # If Application.get_env(:farmbot, :uart_handler, :tty) do...
        redir(conn, "/credentials")

      %{"firmware_hardware" => "custom"} ->
        ConfigStorage.update_config_value(:string, "hardware", "firmware_hardware", "custom")
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
