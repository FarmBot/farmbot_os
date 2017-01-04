defmodule Farmbot.Configurator.Router do
  @moduledoc """
    Routes incoming connections.
  """
  use Plug.Router

  # this is so we can serve the bundle.js file.
  plug Plug.Static, at: "/", from: :farmbot_configurator
  plug :match
  plug :dispatch

  get "/config" do
    conn |> send_resp(200, Poison.encode(%{ foo: "BAR" }))
  end

  # anything that doesn't match a rest end point gets the index.
  match _, do: conn |> send_resp(200, make_html)

  def make_html do
    "#{:code.priv_dir(:farmbot_configurator)}/static/index.html" |> File.read!
  end
end
