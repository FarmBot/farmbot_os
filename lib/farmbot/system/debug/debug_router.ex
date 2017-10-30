defmodule Farmbot.System.DebugRouter do
  use Plug.Router

  if Mix.env() == :dev do
    use Plug.Debugger, otp_app: :farmbot
  end
  plug(Plug.Logger, log: :debug)
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])
  plug(:match)
  plug(:dispatch)

  forward "/wobserver", to: Wobserver.Web.Router
  match(_, do: send_resp(conn, 404, "Page not found"))

end
