defmodule Farmbot.Farmware.Runtime.HTTPServer do
  alias Farmbot.Context
  alias Farmbot.Farmware.Runtime.HTTPServer.JWT
  use   Plug.Router

  plug :match
  plug :dispatch

  # Farmbot.Farmware.Runtime.HTTPServer.delete_me
  def delete_me() do
    start_link(Context.new(), %JWT{}, 8081)
  end

  @doc """
  Starts a (temporary) HTTP Server for Farmware Operation
  """
  def start_link(%Context{} = context, %JWT{} = token, port) do
    Plug.Adapters.Cowboy.http __MODULE__, [jwt: token, context: context], [port: port, ref: :"#{__MODULE__}-#{port}"]
  end

  def stop(port), do: Plug.Adapters.Cowboy.shutdown(:"#{__MODULE__}-#{port}")

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, opts) do
    jwt     = Keyword.fetch!(opts, :jwt)
    ctx     = Keyword.fetch!(opts, :context)
    jwt_enc = jwt |> Poison.encode!() |> :base64.encode()
    case conn |> get_req_header("authorization") do
      ["Bearer " <> ^jwt_enc] -> handle(conn, conn.method, conn.request_path, ctx)
      ["bearer " <> ^jwt_enc] -> handle(conn, conn.method, conn.request_path, ctx)
      _                       -> send_resp(conn, 422, "Bad token")
    end
  end

  defp handle(conn, "GET", "/", _ctx) do
    send_resp(conn, 200, "<html> <head> </head> <body> ... </body> </html>")
  end

  defp handle(conn, "GET", "/status", ctx) do
    ctx
    |> Farmbot.Transport.force_state_push()
    |> Poison.encode!
    |> fn(state) -> conn
      |> put_resp_header("content-type", "application/json")
      |> send_resp(200, state)
    end.()
  end

  defp handle(conn, "POST", "/celery_script", ctx) do
    try do
      {:ok, body, conn} = conn |> read_body()
      ast = body |> Poison.decode! |> Farmbot.CeleryScript.Ast.parse()
      _new_ctx = Farmbot.CeleryScript.Command.do_command(ast, ctx)
      conn
      |> put_resp_header("location", "/status")
      |> send_resp(302, "redirect")
    rescue
      e in Farmbot.CeleryScript.Error -> conn |> send_resp(500, "CeleryScript error: #{inspect e.message}")
      e in Poison.SyntaxError         -> conn |> send_resp(500, "JSON Parse error:   #{e.message}")
      e                               -> conn |> send_resp(500, "Unknown Error:      #{inspect e}")
    end
  end

  defp handle(conn, _, _, _), do: conn |> send_resp(404, "Unknown route.")
  match _ , do: send_resp(conn, 404, "Unknown route.")
end
