defmodule Farmbot.Auth do
  @moduledoc """
    Gets a token and device information
  """
  @modules Application.get_env(:farmbot, :auth_callbacks) ++ [__MODULE__]
  @path Application.get_env(:farmbot, :path)
  @ssl_hack [ ssl: [{:versions, [:'tlsv1.2']}], follow_redirect: true]
  @six_hours (6 * 3_600_000)

  use GenServer
  require Logger
  alias Farmbot.System.FS.ConfigStorage, as: CS
  alias Farmbot.Token

  @doc """
    Gets the public key from the API
  """
  def get_public_key(server) do
    case HTTPoison.get("#{server}/api/public_key", [], @ssl_hack) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, RSA.decode_key(body)}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
      error ->
        {:error, error}
    end
  end

  @doc """
    Returns the list of callback modules.
  """
  def modules, do: @modules

  @doc """
    Encrypts the key with the email, pass, and server
  """
  def encrypt(email, pass, pub_key) do
    f = Poison.encode!(%{"email": email,
                         "password": pass,
                         "id": Nerves.Lib.UUID.generate,
                         "version": 1})
    |> RSA.encrypt({:public, pub_key})
    |> String.Chars.to_string
    {:ok, f}
  end

  @doc """
    Get a token from the server with given token
  """
  @spec get_token_from_server(binary, String.t) :: {:ok, Token.t} | {:error, atom}
  def get_token_from_server(nil, _server), do: {:error, :no_secret}
  def get_token_from_server(_secret, nil), do: {:error, :no_server}

  def get_token_from_server(secret, server) do
    # I am not sure why this is done this way other than it works.
    payload = Poison.encode!(%{user: %{credentials: :base64.encode_to_string(secret) |> String.Chars.to_string }} )
    case HTTPoison.post "#{server}/api/tokens", payload, ["Content-Type": "application/json"], @ssl_hack do
      # bad Password
      {:ok, %HTTPoison.Response{status_code: 422}} ->
        {:error, :bad_password}

      # Token invalid. Need to try to get a new token here.
      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, :expired_token}

      # We won
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        # save the secret to disk.
        Farmbot.System.FS.transaction fn() ->
          :ok = File.write(@path <> "/secret", :erlang.term_to_binary(secret))
          File.rm "tmp/on_failure.sh"
        end
        Poison.decode!(body) |> Map.get("token") |> Token.create

      # HTTP errors
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
    Gets the token.
    Will return a token if one exists, nil if not.
    Returns {:error, reason} otherwise
  """
  def get_token, do: GenServer.call(__MODULE__, :get_token)

  @doc """
    Gets teh server
    will return either {:ok, server} or {:ok, nil}
  """
  @spec get_server :: {:ok, nil} | {:ok, String.t}
  def get_server, do: GenServer.call(CS, {:get, Authorization, "server"}, 9_500)

  @spec put_server(String.t | nil) :: no_return
  defp put_server(server) when is_nil(server) or is_binary(server),
    do: GenServer.cast(CS, {:put, Authorization, {"server", server}})

  @doc """
    Tries to log into web services with whatever auth method is stored in state.
  """
  @spec try_log_in :: {:ok, Token.t} | {:error, atom}
  def try_log_in do
    case GenServer.call(__MODULE__, :try_log_in) do
      {:ok, %Token{} = token} ->
        do_callbacks(token)
        {:ok, token}
      {:error, reason} ->
        Logger.error ">> Could not log in! #{inspect reason}"
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
  def try_log_in!(r) when r == 0, do: Farmbot.System.factory_reset
  def try_log_in!(retries) do
    # Try to get a token.
    case try_log_in() do
       {:ok, %Token{} = _t} = success ->
         Logger.info ">> Is logged in"
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
  @spec interim(String.t, String.t, String.t) :: no_return
  def interim(email, pass, server) do
    GenServer.cast(__MODULE__, {:interim, {email,pass,server}})
  end

  @doc """
    Reads the secret file from disk
  """
  @spec get_secret :: {:ok, nil} | {:ok, binary}
  def get_secret do
    case File.read(@path <> "/secret") do
      {:ok, sec} -> {:ok, :erlang.binary_to_term(sec)}
      _ -> {:ok, nil}
    end
  end

  @doc """
    Starts the Auth GenServer
  """
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Genserver stuff
  def init([]) do
    Logger.info(">> Authorization init!")
    s_a()
    get_secret()
  end

  # sends a message after 6 hours to get a new token.
  defp s_a, do: Process.send_after(__MODULE__, :new_token, @six_hours)

  # casted creds, store them until something is ready to actually try a log in.
  def handle_cast({:interim, {email, pass, server}},_) do
    Logger.info ">> Got some new credentials."
    put_server(server)
    {:noreply, {email,pass,server}}
  end

  def handle_call(:try_log_in, _, {email, pass, server}) do
    Logger.info ">> is trying to log in with credentials."
    with {:ok, pub_key} <- get_public_key(server),
         {:ok, secret } <- encrypt(email, pass, pub_key),
         {:ok, %Token{} = token} <- get_token_from_server(secret, server)
    do
      {:reply, {:ok, token}, token}
    else
      e ->
        Logger.error ">> error getting token #{inspect e}"
        put_server(nil)
        {:reply, e, nil}
    end
  end

  def handle_call(:try_log_in, _, secret) when is_binary(secret) do
    Logger.info ">> is trying to log in with a secret."
    with {:ok, server} <- get_server(),
         {:ok, %Token{} = token} <- get_token_from_server(secret, server)
    do
      {:reply, {:ok, token}, token}
    else
      e ->
        Logger.error ">> error getting token #{inspect e}"
        put_server(nil)
        {:reply, e, nil}
    end
  end

  def handle_call(:try_log_in, _, %Token{} = _token) do
    Logger.warn ">> already has a token. Fetching another."
    with {:ok, server} <- get_server(),
         {:ok, secret} <- get_secret(),
         {:ok, %Token{} = token} <- get_token_from_server(secret, server)
    do
      {:reply, {:ok, token}, token}
    else
      e ->
        Logger.error ">> error getting token #{inspect e}"
        put_server(nil)
        {:reply, e, nil}
    end
  end

  def handle_call(:try_log_in, _, nil) do
    {:ok, secret} = get_secret()
    {:ok, server} = get_server()
    with {:ok, %Token{} = token} <- get_token_from_server(secret, server) do
       {:reply, {:ok, token}, token}
     else
       e ->
         Logger.error ">> can't log in because i have no token or credentials!"
         {:reply, e, nil}
    end
  end


  # if we do have a token.
  def handle_call(:get_token, _from, %Token{} = token) do
    {:reply, {:ok, token}, token}
  end

  # if we dont.
  def handle_call(:get_token, _, not_token) do
    {:reply, nil, not_token}
  end

  # when we get a token.
  def handle_info({:authorization, token}, _) do
    {:noreply, token}
  end

  # NOTE(Connor):
  # This is pretty much a HACK to force MQTT to log in again every six hours
  # Because it goes limp after long amounts of time.
  def handle_info(:new_token, state) do
    spawn fn() ->
      try_log_in()
      s_a()
    end
    {:noreply, state}
  end

  def terminate(:normal, state) do
    Logger.info("AUTH DIED: #{inspect state}")
  end

  def terminate(reason, state) do
    Logger.error("AUTH DIED: #{inspect {reason, state}}")
  end

  defp do_callbacks(token) do
    spawn fn() ->
      for module <- @modules, do: send(module, {:authorization, token})
    end
  end
end
