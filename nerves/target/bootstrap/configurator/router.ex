defmodule Farmbot.Bootstrap.Configurator.Router do
  @moduledoc "Routes web connections."

  use Plug.Router

  if Mix.env == :dev do
    use Plug.Debugger, otp_app: :farmbot
  end

  plug Plug.Static, from: {:farmbot, "priv/static"}, at: "/"
  plug Plug.Session, store: :ets, key: "page", table: :session
  plug Plug.Session, store: :ets, key: "page_complete", table: :session
  plug Plug.Logger, log: :debug
  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  import Farmbot.Bootstrap.Configurator.HTML
  require Logger

  get "/" do
    conn
    |> fetch_session()
    # Reset the page session.
    |> put_session("page_complete", false)
    # Goto 0.
    |> handle_step(0)
  end

  get "/next" do
    # Fetch sessions.
    conn = conn |> fetch_session()
    # get the current page.
    page = conn |> get_session("page")
    # check if the page is complete.
    comp = conn |> get_session("page_complete")
    # Set page complete to false for the next page.
    conn = conn |> put_session("page_complete", false)
    cond do
      # if page is complete, and we are actually on a page go to the next page.
      (comp == true) and (is_number(page)) ->
        conn |> handle_step(page + 1)
      # if we aren't on a page, go back to index.
      is_nil(page) ->
        conn |> put_resp_header("location", "/") |> send_resp(302, "/")
      # Else, just refresh this page.
      true -> do_render(conn, page)
    end
  end

  post "/next" do
    conn
    # Read and store this pages data.
    |> save_data
    # Set page to complete.
    |> put_session("page_complete", true)
    # GET the next page.
    |> put_resp_header("location", "/next")
    |> send_resp(302, "/next")
  end

  post "/finish" do
    conn
    |> save_data()
    |> send_resp(200, "goodbye.")
  end

  get "/flash_fw" do
    Process.sleep(5000)
    conn |> send_resp(200, "ok")
  end

  get "/scan_wifi" do
    conn |> send_resp(200, Poison.encode!(["hello", "world"]))
  end

  defp save_data(conn) do
    {:ok, _, conn} = conn |> fetch_session() |> read_body()
    IO.inspect conn.body_params
    conn
  end

  defp handle_step(conn, num) do
    try do
      conn
      |> put_session("page", num)
      |> do_render(num)
    rescue
      _ ->
        Logger.warn "Resetting page."
        conn
        |> put_session("page", nil)
        |> put_resp_header("location", "/")
        |> send_resp(302, "/")
    end
  end

  defp do_render(conn, num) do
    conn |> send_resp(200, render("page#{num}", conn))
  end

  match _, do: send_resp(conn, 404, "Page not found.")
end
