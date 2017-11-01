defmodule Farmbot.BotState.Transport.HTTP.Router do
  @moduledoc "Underlying router for HTTP Transport."

  use Plug.Router

  alias Farmbot.BotState.Transport.HTTP
  alias HTTP.AuthPlug

  if Mix.env() == :dev do
    use Plug.Debugger, otp_app: :farmbot
  end

  plug Plug.Logger, log: :debug
  plug AuthPlug, env: :prod
  plug :match
  plug :dispatch

  get "/api/v1/bot/state" do
    data = Farmbot.BotState.force_state_push() |> Poison.encode!()
    send_resp conn, 200, data
  end

  get "/socket_test" do
    html = """
    <html>
      <body>
      <script>
        var socket = new WebSocket("ws://localhost:27347/ws")
        socket.onmessage = function (event) {
          console.log(JSON.parse(event.data));
        }
      </script>
      </body>
    </html>
    """
    send_resp(conn, 200, html)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
