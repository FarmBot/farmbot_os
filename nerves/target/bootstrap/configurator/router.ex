defmodule Farmbot.Target.Bootstrap.Configurator.Router do
  @moduledoc "Routes web connections."

  use Plug.Router

  if Mix.env == :dev do
    use Plug.Debugger, otp_app: :farmbot
  end

  plug Plug.Static, from: {:farmbot, "priv/static"}, at: "/"
  plug Plug.Logger, log: :debug
  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  require Logger

  get "/", do: render_page(conn, "index")

  get "/network" do
    info = [interfaces: %{eth0: %{type: :wired}, wlan0: %{type: :wireless, ssids: ["hello", "world"]}}]
    render_page(conn, "network", info)
  end

  post "/configure_network" do
    require IEx; IEx.pry
  end

  match _, do: send_resp(conn, 404, "Page not found")

  defp render_page(conn, page, info \\ []) do
    page
    |> template_file()
    |> EEx.eval_file(info)
    |> fn(contents) -> send_resp(conn, 200, contents) end.()
  rescue
    e -> send_resp(conn, 500, "Failed to render page: #{page} inspect: #{Exception.message(e)}")
  end

  defp template_file(file) do
    "#{:code.priv_dir(:farmbot)}/static/templates/#{file}.html.eex"
  end
end
