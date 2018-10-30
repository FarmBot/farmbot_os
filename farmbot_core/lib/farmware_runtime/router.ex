defmodule Farmbot.FarmwareRuntime.Router do
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Jason
  plug :dispatch

  post "/api/v1/celery_script" do
    # Farmbot.FarmwareRuntime
    decoded = Farmbot.CeleryScript.AST.decode(conn.body_params)
    Farmbot.FarmwareRuntime.schedule(conn.private.runtime_info.runtime_pid, decoded)

    send_resp(conn, 200, "world")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
