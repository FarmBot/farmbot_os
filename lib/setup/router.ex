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
    case parse_conn(conn) do
      :eth ->
        send_resp(conn, 200, "TRYING TO LOG IN")
        if(@env == :prod) do  Wifi.connect(:eth) end
        email = conn.params["email"]
        password = conn.params["password"]
        server = conn.params["server"]
        Auth.login(email,password,server)
        send_resp(conn, 200, "YOU WONT SEE THIS")
      :wifi ->
        send_resp(conn, 200, "TRYING TO LOG IN")
        ssid = conn.params["wifi"]["ssid"]
        psk = conn.params["wifi"]["psk"]
        if(@env == :prod) do  Wifi.connect(ssid, psk) end
        email = conn.params["email"]
        password = conn.params["password"]
        server = conn.params["server"]
        Auth.login(email,password,server)
        send_resp(conn, 200, "YOU WONT SEE THIS")
    end
  end

  get "/" do
    send_resp(conn, 200, Poison.encode!(BotState.get_status) )
  end

  get "/scan" do
    send_resp(conn, 200, Poison.encode!(scan(@env)) )
  end

  get "/tea" do
    send_resp(conn, 418, "IM A TEAPOT")
  end

  def scan(:prod) do
    Wifi.scan
  end

  def scan(_) do
    ["not", "on", "real", "hardware"]
  end

  @doc """
    This is so ugly
  """
  def parse_conn(conn) do
    required_keys = ["email","password","server"]
    with_wifi = ["wifi"]
    with_eth = ["ethernet"]
    if(Enum.all?(required_keys, fn(key) -> Map.has_key?(conn.params, key) end )) do
      # We have at least enough to try to log in.
      if(Enum.all?(with_wifi, fn(key) -> Map.has_key?(conn.params, key) end )) do
        :wifi
      else
        if(Enum.all?(with_eth, fn(key) -> Map.has_key?(conn.params, key) end )) do
          :eth
        end
      end
    else
      send_resp(conn, 401, "BAD PARAMS")
    end
  end

  match _ do
    send_resp(conn, 404, "Whatever you did could not be found.")
  end
end
