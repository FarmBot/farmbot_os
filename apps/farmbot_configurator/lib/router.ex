defmodule Farmbot.Configurator.Router do
  @moduledoc """
    Routes incoming connections.
  """
  use Plug.Router

  plug Plug.Static, at: "/", from: :farmbot_configurator
  plug :match
  plug :dispatch

  match _, do: conn |> send_resp(200, make_html)

  def make_html do
    "#{:code.priv_dir(:farmbot_configurator)}/static/index.html"
    |> File.read!
  end
end
