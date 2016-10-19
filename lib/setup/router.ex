defmodule MyRouter do
  @env Mix.env
  use Plug.Router
  require Logger
  plug CORSPlug
  plug Plug.Parsers, parsers: [:urlencoded, :json],
                     pass:  ["text/*"],
                     json_decoder: Poison
  plug :match
  plug :dispatch

  post "/login" do
    case Map.has_key?(conn.params, "email")
     and Map.has_key?(conn.params, "password")
     and Map.has_key?(conn.params, "server")
     and Map.has_key?(conn.params, "wifi") do
       true ->
         email = conn.params["email"]
         ssid = conn.params["wifi"]["ssid"]
         psk = conn.params["wifi"]["psk"]
         if(@env == :prod) do  Wifi.connect(ssid, psk) end
         password = conn.params["password"]
         server = conn.params["server"]
         case Auth.login(email,password,server) do
           nil -> send_resp(conn, 401, "LOGIN FAIL")
           _ -> send_resp(conn, 200, "LOGIN OK")
         end
       _ ->
         send_resp(conn, 401, "BAD PARAMS")

     end
  end

  get "/scan" do
    send_resp(conn, 200, Poison.encode!(scan(@env)) )
  end

  def scan(:prod) do
    Wifi.scan
  end

  def scan(_) do
    ["not", "on", "real", "hardware"]
  end

  get "/tea" do
    send_resp(conn, 418, "IM A TEAPOT")
  end

  match _ do
    send_resp(conn, 404, "Whatever you did could not be found.")
  end
end
