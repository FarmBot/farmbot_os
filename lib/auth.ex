defmodule Auth do
  @path Application.get_env(:fb, :ro_path)
  require GenServer
  require Logger

  @moduledoc """
    This is a small disaster ever growing into a bigger disaster.
  """

  def get_public_key(server) do
    resp = HTTPotion.get("#{server}/api/public_key")
    case resp do
      %HTTPotion.ErrorResponse{message: "enetunreach"} -> get_public_key(server)
      %HTTPotion.ErrorResponse{message: "ehostunreach"} -> get_public_key(server)
      %HTTPotion.ErrorResponse{message: "econnrefused"} -> {:error, "econnrefused"}
      _ -> RSA.decode_key(resp.body)
    end
  end

  def encrypt(email, pass, server) do
    # Json to encrypt.
    json = Poison.encode!(%{"email": email,"password": pass,
        "id": Nerves.Lib.UUID.generate,"version": 1})
    secret = String.Chars.to_string(RSA.encrypt(json, {:public, get_public_key(server)}))
    save_encrypted(secret, server)
    secret
  end

  @doc """
    Saves the secret and the server to disk.
  """
  def save_encrypted(secret, server) do
    File.write("#{@path}/secretes.txt", :erlang.term_to_binary(%{secret: secret, server: server}))
  end

  @doc """
    Loads the secret and server from disk
    if there is no file returns nil
  """
  def load_encrypted do
    file = File.read("#{@path}/secretes.txt")
    case file do
      {:ok, contents} -> t = :erlang.binary_to_term(contents)
                         get_token(Map.get(t, :secret), Map.get(t, :server))
      _ -> nil
    end
  end

  # Gets a token from the API with given secret and server
  def get_token(secret, server) do
    payload = Poison.encode!(%{user: %{credentials: :base64.encode_to_string(secret) |> String.Chars.to_string }} )
    resp = HTTPotion.post "#{server}/api/tokens", [body: payload, headers: ["Content-Type": "application/json"]]
    case resp do
      %HTTPotion.ErrorResponse{message: "enetunreach"} -> get_token(secret, server)
      %HTTPotion.ErrorResponse{message: reason} -> {:error, reason}
      _ -> Map.get(Poison.decode!(resp.body), "token")
    end
  end

  def get_token do
    GenServer.call(__MODULE__, {:get_token})
  end

  # Infinite recursion until we have a token.
  # Not concerned about performance yet because the bot can't do anything yet.
  def fetch_token do
    case Auth.get_token do
      nil -> fetch_token
      token -> token
    end
  end

  # Genserver stuff
  def init(_args) do
    {:ok, load_encrypted}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__ )
  end

  # Am i even using this?
  def login(email,pass,server) when is_bitstring(email)
        and is_bitstring(pass)
        and is_bitstring(server) do
    case Wifi.connected? do
      true ->
        GenServer.call(__MODULE__, {:login, email,pass,server})
      _ ->
        login(email,pass,server) # Probably process heavy here but im lazy
    end
  end

  def handle_call({:login, email,pass,server}, _from, _old_token) do
    secret = encrypt(email,pass,server)
    token = get_token(secret, server)
    {:reply,token,token}
  end

  def handle_call({:get_token}, _from, token) do
    {:reply, token, token}
  end
end
