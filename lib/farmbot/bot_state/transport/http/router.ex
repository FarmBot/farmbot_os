defmodule Farmbot.BotState.Transport.HTTP.Router do
  @moduledoc "Underlying router for HTTP Transport."

  use Plug.Router

  alias Farmbot.BotState.Transport.HTTP
  alias HTTP.AuthPlug

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
    send_resp conn, 200, ""
  end

  post "/api/v1/celery_script" do
    with {:ok, _, conn} <- conn |> read_body(),
         {:ok, ast} <- Farmbot.CeleryScript.AST.decode(conn.params)
    do
      case Farmbot.CeleryScript.execute(ast) do
        {:ok, _} -> send_resp(conn, 200, "ok")
        {:error, reason} when is_binary(reason) or is_atom(reason) ->
          send_resp conn, 500, reason
        {:error, reason} -> send_resp conn, 500, "#{inspect reason}"
      end
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
end
