defmodule Farmbot.FarmwareRuntime.Router do
  use Plug.Router
  alias Farmbot.{CeleryScript.AST, FarmwareRuntime, BotState, JSON}

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: JSON
  )

  plug(:auth)
  plug(:json_content_type)
  plug(:dispatch)

  def auth(conn, _opts) do
    # TODO(Connor) fixme
    conn
  end

  def json_content_type(conn, _opts) do
    conn
    |> put_resp_content_type("application/json")
  end

  post "/api/v1/celery_script" do
    decoded = AST.decode(conn.body_params)
    ast = AST.new(:rpc_request, %{label: "farmware"}, [decoded])
    result = FarmwareRuntime.schedule(conn.private.runtime_info.runtime_pid, ast)
    send_resp(conn, 200, JSON.encode!(result))
  end

  get "/api/v1/bot_state" do
    state = BotState.fetch()
    send_resp(conn, 200, JSON.encode!(state))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
