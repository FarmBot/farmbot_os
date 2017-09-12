defmodule Farmbot.Bootstrap.Configurator.Router do
  @moduledoc "Routes web connections."

  use Plug.Router

  plug Plug.Static, from: {:farmbot, "priv/static"}, at: "/static"
  plug :match
  plug :dispatch

  import Farmbot.Bootstrap.Configurator.HTML

  get "/" do
    conn |> send_resp(200, render("index"))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
