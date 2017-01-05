defmodule Farmbot.Configurator.Router do
  @moduledoc """
    Routes incoming connections.
  """
  use Plug.Router
  alias Farmbot.FileSystem.ConfigStorage
  # this is so we can serve the bundle.js file.
  plug Plug.Static, at: "/", from: :farmbot_configurator
  plug :match
  plug :dispatch

  get "/config" do
    {:ok, config} = ConfigStorage.read_config_file
    conn |> send_resp(200, config)
  end

  post "/config" do
    {:ok, body, _} = read_body(conn)
    rbody = Poison.decode!(body)
    ConfigStorage.replace_config_file(rbody)
    conn |> send_resp(200,body)
  end

  post "/config/creds" do
    {:ok, body, _} = read_body(conn)
    %{email: email, pass: pass, server: server} = Poison.decode!(body)
    conn |> send_resp(200, "ok")
  end

  get "/network/interfaces" do
    conn |> send_resp(501, "TODO")
  end

  get "/network/scan" do
    conn |> send_resp(501, "TODO")
  end

  # anything that doesn't match a rest end point gets the index.
  match _, do: conn |> send_resp(200, make_html)

  def make_html do
    "#{:code.priv_dir(:farmbot_configurator)}/static/index.html" |> File.read!
  end
end
