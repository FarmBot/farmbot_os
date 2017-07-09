defmodule Farmbot.Farmware.HTTPServer do
  alias Farmbot.Context
  alias Farmbot.Farmware.JWT
  use   Plug.Router

  @max_length 111_409_842
  plug Plug.Parsers, parsers:
    [:urlencoded, :multipart, :json], json_decoder: Poison, length: @max_length
  plug :match
  plug :dispatch

  def start_link(%Context{} = context, %JWT{} = token) do
    Plug.Adapters.Cowboy.http __MODULE__, [jwt: token], [port: 8081]
  end

  def init(opts), do: opts

  def call(conn, opts) do
    jwt     = Keyword.fetch!(opts, :jwt)
    jwt_enc = jwt |> Poison.encode!() |> :base64.encode()
    case conn |> get_req_header("authorization") do
      ["bearer " <> ^jwt_enc] -> send_resp(conn, 200, "ok")
      [^jwt_enc] -> send_resp(conn, 200, "ok")
      _ -> send_resp(conn, 422, "Bad token")
    end
  end

  match _, do: send_resp(conn, 500, "wuh oh")
end
