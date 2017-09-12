defmodule Farmbot.Bootstrap.Configurator.Router do
  @moduledoc "Routes web connections."

  use Plug.Router

  plug Plug.Static, from: {:farmbot, "priv/static"}, at: "/"
  plug Plug.Session, store: :ets, key: "session", table: :session
  plug :match
  plug :dispatch

  import Farmbot.Bootstrap.Configurator.HTML

  get "/" do
    conn = conn |> fetch_session()
    # session = conn |> get_session("session")
    conn
    |> put_session("session", 0)
    |> send_resp(200, render("page0"))
  end

  get "/previous" do
    conn = conn |> fetch_session()
    session = conn |> get_session("session")
    cond do
      is_nil(session) ->
        conn
        |> put_session("session", 0)
        |> send_resp(200, render("page0"))
      is_number(session) ->
        conn |> handle_step(session - 1)
    end
  end

  get "/next" do
    conn = conn |> fetch_session()
    session = conn |> get_session("session")
    cond do
      is_nil(session) ->
        conn
        |> put_session("session", 0)
        |> send_resp(200, render("page0"))
      is_number(session) ->
        conn |> handle_step(session + 1)
    end
  end

  defp handle_step(conn, num) do
    try do
      conn
      |> put_session("session", num)
      |> send_resp(200, render("page#{num}"))
    rescue
      _ ->
        conn
        |> put_session("session", 0)
        |> send_resp(200, render("page0"))
    end
  end

  match _, do: send_resp(conn, 404, "Page not found.")
end
