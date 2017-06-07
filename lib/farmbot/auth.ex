defmodule Farmbot.Auth do
  @moduledoc """
    Gets a token and device information
  """

  @timeout_time (2 * 3_600_000)

  require Logger
  alias   Farmbot.{Token, Context, DebugLog, System, HTTP}
  alias   System.FS
  alias   FS.ConfigStorage, as: CS
  alias   Farmbot.Auth.Subscription, as: Sub
  use     GenServer
  use     DebugLog

  @typedoc """
    The public key that lives at http://<server>/api/public_key
  """
  @type public_key :: binary

  @typedoc false
  @type auth :: pid | atom

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
  @spec get_public_key(Context.t, server) :: {:ok, public_key} | {:error, term}
  def get_public_key(%Context{} = ctx, server) do
    case HTTP.get(ctx, "#{server}/api/public_key") do
      {:ok, %HTTP.Response{body: body, status_code: 200}} ->
        decode_key(body)
      {:error, reason} ->
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
  @spec get_token_from_server(Context.t, secret, server, boolean)
    :: {:ok, Token.t} | {:error, term}
  def get_token_from_server(context, secret, server, should_broadcast?)

  def get_token_from_server(_context, nil, _server, sbc) do
    thing = {:error, :no_secret}
    if sbc do
      broadcast(thing)
    end
    thing
  end

  # This one shouldn't happen anymore I think.
  def get_token_from_server(_context, _secret, nil, sbc) do
    thing = {:error, :no_server}
    if sbc do
      broadcast(thing)
    end
    thing
  end

  def get_token_from_server(%Context{} = ctx, secret, server, sbc) do
    # I am not sure why this is done this way other than it works.
    user = %{credentials: secret |> :base64.encode_to_string |> to_string}
    payload = Poison.encode!(%{user: user})
    req = HTTP.post(ctx, "#{server}/api/tokens", payload, [], [])

    case req do
      # bad Password
      {:ok, %HTTP.Response{status_code: 422}} ->
        thing = {:error, :bad_password}
        maybe_broadcast(sbc, thing)
        thing

      # Token invalid. Need to try to get a new token here.
      {:ok, %HTTP.Response{status_code: 401}} ->
        thing = {:error, :expired_token}
        maybe_broadcast(sbc, thing)
        thing

      # We won
      {:ok, %HTTP.Response{body: body, status_code: 200}} ->
        Logger.info ">> got a token!", type: :success
        save_secret(secret)
        remove_last_factory_reset_reason()
        {:ok, token} = body |> Poison.decode! |> Map.get("token") |> Token.create
        token = %{token | unencoded: %{token.unencoded | iss: server}}
        maybe_broadcast(sbc, {:new_token, token})
        {:ok, token}

      # HTTP errors
      {:error, _reason} = thing ->
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
  @spec purge_token(auth) :: :ok | {:error, atom}
  def purge_token(auth), do: GenServer.call(auth, :purge_token)

  @doc """
    Gets the token.
    Will return a token if one exists, nil if not.
    Returns {:error, reason} otherwise
  """
  @spec get_token(auth) :: {:ok, Token.t} | nil | {:error, term}
  def get_token(auth), do: GenServer.call(auth, :get_token)

  @doc """
    Gets the server.
  """
  @spec get_server(auth) :: server
  def get_server(auth), do: GenServer.call(auth, :get_server)

  @doc """
    Tries to log into web services with whatever auth method is stored in state.
  """
  @spec try_log_in(auth) :: {:ok, Token.t} | {:error, atom}
  def try_log_in(auth) do
    case GenServer.call(auth, :try_log_in) do
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
  @spec try_log_in!(auth, integer, binary) :: {:ok, Token.t} | no_return
  def try_log_in!(auth, retries \\ 0 , error_str \\ "")

  def try_log_in!(_auth, r, error_str) when r >= 3 do
    Logger.info ">> Could not log in!", type: :error
    Farmbot.System.factory_reset("""
    Could not log in to web application.
    This is probably due to a bad username or password.
    #{error_str}
    """)
  end

  def try_log_in!(auth, retry, error_str) do
    Logger.info ">> is logging in..."
    # disable broadcasting
    :ok = GenServer.call(auth, {:set_broadcast, false})

    # Try to get a token.
    case try_log_in(auth) do
       {:ok, %Token{} = token} = success ->
         :ok = GenServer.call(auth, {:set_broadcast, true})

         Logger.info ">> Is logged in", type: :success
         broadcast({:new_token, token})
         success
       er -> # no need to print message becasetry_log_indoes it for us.
        # sleep for a second, then try again untill we are out of retry
        Process.sleep(1000)
        try_log_in!(retry + 1, "Try #{retry}: #{inspect er}\n" <> error_str)
    end
  end

  @doc """
    Casts credentials to the Auth GenServer
  """
  @spec interim(auth, email, password, server) :: :ok
  def interim(auth, email, pass, server) do
    GenServer.call(auth, {:interim, {email,pass,server}})
  end

  @doc """
    Starts the Auth GenServer
  """
  def start_link(context, opts), do: GenServer.start_link(__MODULE__, context, opts)

  @typedoc """
    State for this GenServer
  """
  @type state :: %{
    context:   Context.t,
    server:    nil | server,
    secret:    nil | secret,
    timer:     any,
    interim:   nil | interim,
    token:     nil | Token.t,
    broadcast: boolean
  }

  ## Genserver stuff

  def init(context) do
    Logger.info(">> Authorization init!")
    timer         = s_a(self())
    context       = %Context{context | auth: self()}
    {:ok, sub}    = Sub.start_link(context, [])
    {:ok, server} = load_server()
    state = %{
      context:   context,
      server:    server,
      sub:       sub,
      secret:    load_secret(),
      interim:   nil,
      token:     nil,
      timer:     timer,
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
    case get_token_from_server(state.context, secret, server, state.broadcast) do
      {:ok, %Token{} = token} ->
        {:reply, {:ok, token}, %{state | token: token}}
      e ->
        {:reply, e, clear_state(state)}
    end
  end

  # Next choice will be interim
  def handle_call(:try_log_in, _, %{interim: {email, pass, server}} = state) do
    Logger.info ">> is trying to log in with credentials.", type: :busy
    {:ok, pub_key} = get_public_key(state.context, server)
    {:ok, secret } = encrypt(email, pass, pub_key)
    case get_token_from_server(state.context, secret, server, state.broadcast) do
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
    case get_token_from_server(state.context, secret, server, state.broadcast) do
      {:ok, %Token{} = t} ->
        {:reply, {:ok, t}, %{state | token: t}}
      e -> {:reply, e, clear_state(state)}
    end
  end

  def handle_call(:try_log_in, _, %{secret: nil, server: server} = state) do
    Logger.info ">> is trying to load old secret.", type: :busy
    # Try to load the secret file
    secret = load_secret()
    case get_token_from_server(state.context, secret, server, state.broadcast) do
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
      try_log_in(self())
    end
    new_timer = s_a(self())
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

  @spec remove_last_factory_reset_reason :: no_return
  defp remove_last_factory_reset_reason do
    FS.transaction fn() ->
      File.rm "#{FS.path()}/factory_reset_reason"
    end
  end

  # sends a message after 6 hours to get a new token.
  defp s_a(auth), do: Process.send_after(auth, :new_token, @timeout_time)
end
