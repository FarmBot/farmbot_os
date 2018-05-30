defmodule Farmbot.BotState.Transport.HTTP.Router do
  @moduledoc "Underlying router for HTTP Transport."

  use Plug.Router

  alias Farmbot.BotState.Transport.HTTP
  alias HTTP.AuthPlug
  alias Farmbot.CeleryScript.AST

  use Plug.Debugger, [otp_app: :farmbot]
  plug Plug.Logger, [log: :debug]
  plug AuthPlug, [env: Farmbot.Project.env()]
  plug Plug.Parsers, [
    parsers: [:urlencoded, :multipart, :json],
    json_decoder: Poison]
  plug :match
  plug :dispatch

  get "/api/v1/bot/state" do
    data = Farmbot.BotState.force_state_push() |> Poison.encode!()
    send_resp conn, 200, data
  end

  get "/api/v1/bot/speak" do
    case conn.params do
      %{"text" => text} when is_binary(text) ->
        System.cmd("espeak", [text])
    end
    send_resp conn, 200, "text"
  end

  post "/api/v1/celery_script" do
    with {:ok, _, conn} <- conn |> read_body(),
         {:ok, ast} <- AST.decode(conn.params)
    do
      handle_celery_script(conn, ast)
    else
      err -> send_resp conn, 500, "#{inspect err}"
    end
  end

  # THIS IS A LEGACY ENDPOINT
  post "/celery_script" do
    loc = "/api/v1/celery_script"
    conn = put_resp_header(conn, "location", loc)
    send_resp(conn, 300, loc)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def handle_celery_script(conn, %AST{kind: AST.Node.RpcRequest, body: body} = ast) do
    case do_reduce(body, struct(Macro.Env, [])) do
      {:ok, _} ->
        resp = %AST{kind: AST.Node.RpcOk, args: ast.args, body: []}
        {:ok, encoded} = AST.encode(resp)
        send_resp conn, 200, Poison.encode!(encoded)
      {:error, reason, _} ->
        expl = %AST{kind: AST.Node.Explanation, args: %{message: "#{inspect ast} failed: #{inspect reason}"}, body: []}
        resp = %AST{kind: AST.RpcError, args: ast.args, body: [expl]}
        {:ok, encoded} = AST.encode(resp)
        send_resp conn, 200, Poison.encode!(encoded)
    end
  end

  def handle_celery_script(conn, ast) do
    case Farmbot.CeleryScript.execute(ast) do
      {:ok, _} -> send_resp(conn, 200, "ok")
      {:error, reason, _} when is_binary(reason) or is_atom(reason) ->
        send_resp conn, 500, reason
      {:error, reason, _} -> send_resp conn, 500, "#{inspect reason}"
    end
  end

  defp do_reduce([%AST{} = ast | rest], env) do
    case Farmbot.CeleryScript.execute(ast, env) do
      {:ok, env} -> do_reduce(rest, env)
      {:error, reason, env} -> {:error, reason, env}
    end
  end
end
