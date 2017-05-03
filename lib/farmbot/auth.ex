defmodule Farmbot.Auth do
  @moduledoc """
    Gets a token and device information
  """

  @ssl_hack [
    ssl: [{:versions, [:'tlsv1.2']}],
    follow_redirect: true
  ]
  @six_hours (6 * 3_600_000)

  use GenServer
  require Logger
  alias Farmbot.System.FS
  alias FS.ConfigStorage, as: CS
  alias Farmbot.Token
  alias Farmbot.Auth.Subscription, as: Sub

  @typedoc """
    The public key that lives at http://<server>/api/public_key
  """
  @type public_key :: binary

  @typedoc """
    Encrypted secret
  """
  @type secret :: binary

  @typedoc """
    Server auth is connected to.
  """
  @type server :: binary

  @typedoc """
    Password binary
  """
  @type password :: binary

  @typedoc """
    Email binary
  """
  @type email :: binary

  @typedoc """
    Interim credentials.
  """
  @type interim :: {email, password, server}

  @doc """
    Gets the public key from the API
  """
  @spec get_public_key(server) :: {:ok, public_key} | {:error, term}
  def get_public_key(server) do
    case HTTPoison.get("#{server}/api/public_key", [], @ssl_hack) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        decode_key(body)
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @spec decode_key(binary) :: {:ok, public_key} | {:error, term}
  defp decode_key(binary) do
    r = RSA.decode_key(binary)
    {:ok, r}
    rescue
      e -> {:error, e}
  end

  @doc """
    Encrypts the key with the email, pass, and server
  """
  @spec encrypt(email, password, public_key) :: {:ok, binary} | {:error, term}
  def encrypt(email, pass, pub_key) do
    f = %{
      "email": email,
      "password": pass,
      "id": Nerves.Lib.UUID.generate,
      "version": 1}
    |> Poison.encode!()
    |> RSA.encrypt({:public, pub_key})
    |> String.Chars.to_string
    {:ok, f}
    rescue
      e -> {:error, e}
  end

  @doc """
    Get a token from the server with given token
  """
  @spec get_token_from_server(secret, server, boolean)
    :: {:ok, Token.t} | {:error, term}
  def get_token_from_server(secret, server, should_broadcast?)

  def get_token_from_server(nil, _server, sbc) do
    thing = {:error, :no_secret}
    if sbc do
      broadcast(thing)
    end
    thing
  end

  # This one shouldn't happen anymore I think.
  def get_token_from_server(_secret, nil, sbc) do
    thing = {:error, :no_server}
    if sbc do
      broadcast(thing)
    end
    thing
  end

  def get_token_from_server(secret, server, sbc) do
    # I am not sure why this is done this way other than it works.
    user = %{credentials: secret |> :base64.encode_to_string |> to_string}
    payload = Poison.encode!(%{user: user})
    req = HTTPoison.post("#{server}/api/tokens",
      payload, ["Content-Type": "application/json"], @ssl_hack)

    case req do
      # bad Password
      {:ok, %HTTPoison.Response{status_code: 422}} ->
        thing = {:error, :bad_password}
        maybe_broadcast(sbc, thing)
        thing

      # Token invalid. Need to try to get a new token here.
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        thing = {:error, :expired_token}
        maybe_broadcast(sbc, thing)
        thing

      # We won
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        Logger.info ">> got a token!", type: :success
        save_secret(secret)
        {:ok, token} = body |> Poison.decode! |> Map.get("token") |> Token.create
        maybe_broadcast(sbc, {:new_token, token})
        {:ok, token}

      # HTTP errors
      {:error, %HTTPoison.Error{reason: reason}} ->
        thing = {:error, reason}
        maybe_broadcast(sbc, thing)
        thing
    end
  end

  @spec maybe_broadcast(boolean, any) :: no_return
  defp maybe_broadcast(bool, thing) do
    if bool do
      broadcast(thing)
    end
  end

  @doc """
    Purges the token and creds.
  """
  @spec purge_token :: :ok | {:error, atom}
  def purge_token, do: GenServer.call(__MODULE__, :purge_token)

  @doc """
    Gets the token.
    Will return a token if one exists, nil if not.
    Returns {:error, reason} otherwise
  """
  @spec get_token :: {:ok, Token.t} | nil | {:error, term}
  def get_token, do: GenServer.call(__MODULE__, :get_token)

  @doc """
    Gets the server.
  """
  @spec get_server :: server
  def get_server, do: GenServer.call(__MODULE__, :get_server)

  @doc """
    Tries to log into web services with whatever auth method is stored in state.
  """
  @spec try_log_in :: {:ok, Token.t} | {:error, atom}
  def try_log_in do
    case GenServer.call(__MODULE__, :try_log_in) do
      {:ok, %Token{} = token} ->
        {:ok, token}
      {:error, reason} ->
        Logger.info ">> Could not log in! #{inspect reason}", type: :error
        {:error, reason}
      error ->
        Logger.error ">> Could not log in! #{inspect error}"
        {:error, error}
    end
  end

  # We want to try to get a token, and if it fails, we basically are going to
  # End up in a limp state, so here if we dont get a token, just factory reset
  @doc """
    Tries to log in, but factory resets if it doesnt work
  """
  @spec try_log_in!(integer) :: {:ok, Token.t} | no_return
  def try_log_in!(retries \\ 3)

  def try_log_in!(r) when r == 0 do
    Logger.info ">> Could not log in!", type: :error
    Farmbot.System.factory_reset
  end

  def try_log_in!(retries) do
    Logger.info ">> is logging in..."
    # disable broadcasting
    :ok = GenServer.call(__MODULE__, {:set_broadcast, false})

    # Try to get a token.
    case try_log_in() do
       {:ok, %Token{} = token} = success ->
         :ok = GenServer.call(__MODULE__, {:set_broadcast, true})

         Logger.info ">> Is logged in", type: :success
         broadcast({:new_token, token})
         success
       _ -> # no need to print message becasetry_log_indoes it for us.
        # sleep for a second, then try again untill we are out of retries
        Process.sleep(1000)
        try_log_in!(retries - 1)
    end
  end

  @doc """
    Casts credentials to the Auth GenServer
  """
  @spec interim(email, password, server) :: :ok
  def interim(email, pass, server) do
    GenServer.call(__MODULE__, {:interim, {email,pass,server}})
  end

  @doc """
    Starts the Auth GenServer
  """
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @typedoc """
    State for this GenServer
  """
  @type state :: %{
    server: nil | server,
    secret: nil | secret,
    timer: any,
    interim: nil | interim,
    token: nil | Token.t,
    broadcast: boolean
  }

  # Genserver stuff
  def init([]) do
    Logger.info(">> Authorization init!")
    timer = s_a()
    {:ok, sub} = Sub.start_link
    {:ok, server} = load_server()
    state = %{
      server: server,
      secret: load_secret(),
      interim: nil,
      token: nil,
      timer: timer,
      sub: sub,
      broadcast: true
    }
    {:ok, state}
  end

  def terminate(_reason, state) do
    timer = state.timer
    if timer do
      Process.cancel_timer(timer)
    end
  end

  def handle_call({:set_broadcast, bool}, _, state) do
    {:reply, :ok, %{state | broadcast: bool}}
  end

  def handle_call(:get_server, _, state) do
    {:reply, {:ok, state.server}, state}
  end

  # casted creds, store them until something is ready to actually try a log in.
  def handle_call({:interim, {email, pass, server}}, _from, state) do
    Logger.info ">> Got some new credentials."
    save_server(server)
    {:reply, :ok, %{state | interim: {email, pass, server}}}
  end

  def handle_call(:purge_token, _, state) do
    broadcast :purge_token
    {:reply, :ok, clear_state(state)}
  end

  # Match on the token first.
  def handle_call(:try_log_in, _, %{token: %Token{}= _old, server: server, secret: secret} = state) do
    Logger.info ">> already has a token. Fetching another.", type: :busy
    secret = secret || load_secret()
    case get_token_from_server(secret, server, state.broadcast) do
      {:ok, %Token{} = token} ->
        {:reply, {:ok, token}, %{state | token: token}}
      e ->
        {:reply, e, clear_state(state)}
    end
  end

  # Next choice will be interim
  def handle_call(:try_log_in, _, %{interim: {email, pass, server}} = state) do
    Logger.info ">> is trying to log in with credentials.", type: :busy
    {:ok, pub_key} = get_public_key(server)
    {:ok, secret } = encrypt(email, pass, pub_key)
    case get_token_from_server(secret, server, state.broadcast) do
      {:ok, %Token{} = token} ->
        next_state = %{state |
          interim: nil,
          token: token,
          secret: secret,
          server: server
        }
        {:reply, {:ok, token}, next_state}
      e -> {:reply, e, clear_state(state)}
    end
  end

  def handle_call(:try_log_in, _,
      %{secret: secret, server: server} = state) when is_binary(secret) do

    Logger.info ">> is trying to log in with a secret.", type: :busy
    case get_token_from_server(secret, server, state.broadcast) do
      {:ok, %Token{} = t} ->
        {:reply, {:ok, t}, %{state | token: t}}
      e -> {:reply, e, clear_state(state)}
    end
  end

  def handle_call(:try_log_in, _, %{secret: nil, server: server} = state) do
    Logger.info ">> is trying to load old secret.", type: :busy
    # Try to load the secret file
    secret = load_secret()
    case get_token_from_server(secret, server, state.broadcast) do
      {:ok, %Token{} = token} ->
        {:reply, {:ok, token}, token}
      e ->
        {:reply, e, state}
    end
  end

  # if we do have a token.
  def handle_call(:get_token, _, %{token: %Token{}} = state) do
    {:reply, {:ok, state.token}, state}
  end

  # if we dont.
  def handle_call(:get_token, _, %{token: nil} = state) do
    {:reply, nil, state}
  end

  # NOTE(Connor):
  # This is pretty much a HACK to force MQTT to log in again every six hours
  # Because it goes limp after long amounts of time.
  def handle_info(:new_token, state) do
    spawn fn() ->
      try_log_in()
    end
    new_timer = s_a()
    {:noreply, %{state | timer: new_timer}}
  end

  defp broadcast(message) do
    Registry.dispatch(Farmbot.Registry, __MODULE__, fn entries ->
      for {pid, _} <- entries, do: send(pid, {__MODULE__, message})
    end)
  end

  @spec clear_state(state) :: state
  defp clear_state(state) do
    %{state | interim: nil, secret: nil, token: nil}
  end

  @spec load_server :: {:ok, server}
  defp load_server,
    do: GenServer.call(CS, {:get, Authorization, "server"}, 9_500)

  @spec save_server(server) :: :ok
  defp save_server(server) when is_binary(server),
    do: GenServer.cast(CS, {:put, Authorization, {"server", server}})

  @spec load_secret :: secret | nil
  defp load_secret do
    case File.read(FS.path() <> "/secret") do
      {:ok, sec} -> :erlang.binary_to_term(sec)
      _e -> nil
    end
  end

  @spec save_secret(secret) :: no_return
  defp save_secret(secret) do
    # save the secret to disk.
    FS.transaction fn() ->
      File.write(FS.path() <> "/secret", :erlang.term_to_binary(secret))
    end
  end

  # sends a message after 6 hours to get a new token.
  defp s_a, do: Process.send_after(__MODULE__, :new_token, @six_hours)
end
