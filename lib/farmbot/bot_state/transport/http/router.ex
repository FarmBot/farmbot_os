defmodule Farmbot.BotState.Transport.HTTP.Router do
  @moduledoc "Underlying router for HTTP Transport."

  use Plug.Router

  alias Farmbot.BotState.Transport.HTTP
  alias HTTP.AuthPlug

  if Mix.env() == :dev do
    use Plug.Debugger, otp_app: :farmbot
  end

  plug Plug.Logger, log: :debug
  plug AuthPlug, env: Mix.env()
  plug :match
  plug :dispatch

  get "/api/v1/bot/state" do
    data = Farmbot.BotState.force_state_push() |> Poison.encode!()
    send_resp conn, 200, data
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
