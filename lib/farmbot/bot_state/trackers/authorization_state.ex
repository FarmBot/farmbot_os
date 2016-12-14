defmodule Farmbot.BotState.Authorization do
  use GenServer
  require Logger
  alias Farmbot.Auth

  @moduledoc """
    Tracks authorization state.
  """
  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
      token: Token.t | nil,
      secret: nil | binary,
      server: nil | String.t,
      interim: nil | %{
        email: String.t,
        pass: String.t
      }
    }
    defstruct [
      token: nil,
      secret: nil,
      server: nil,
      interim: nil
    ]

    @spec broadcast(t) :: t
    def broadcast(%State{} = state) do
      GenServer.cast(Farmbot.BotState.Monitor, state)
      state
    end
  end

  def init(_args) do
    s =
      __MODULE__
      |> SafeStorage.read
      |> load
      |> maybe_get_token(Auth.get_token)
      |> State.broadcast
    {:ok, s}
  end

  @spec load({:ok, State.t} | nil) :: State.t
  defp load({:ok, %State{} = state}), do: state
  defp load(nil), do: %State{}

  @spec maybe_get_token(State.t, {:ok, Token.t} | nil) :: State.t
  defp maybe_get_token(%State{} = state, {:ok, token}) do
    %State{state | token: Token.create!(token)}
  end

  defp maybe_get_token(%State{} = state, nil) do
    %State{state| token: nil}
  end


  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Gets the server
  def handle_call(:get_server, _from, %State{} = state) do
    dispatch state.server, state
  end

  def handle_call(:get_token, _from, %State{} = state) do
    dispatch state.token, state
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.error ">> got an unhandled call in Auth tracker: #{inspect event}"
    dispatch :unhandled, state
  end

  # I CAN DO BETTER
  def handle_cast(:try_log_in, %State{} = state) do
    dispatch try_log_in(state)
  end

  # We have to store these temporarily in case the bot doesnt have network yet.
  def handle_cast({:creds, {email, pass, server}}, %State{} = _state) do
    new_state =
      %State{server: server, interim: %{email: email, pass: pass}}
    dispatch new_state
  end

  def handle_cast(event, %State{} = state) do
    Logger.error ">> got an unhandled cast in Auth tracker: #{inspect event}"
    dispatch state
  end

  # this is pretty much only for testing.
  def handle_info({:authorization, %Token{} = token}, %State{} = state) do
    new_state =
      %State{state | token: token, server: token.unencoded.iss}
    dispatch new_state
  end

  defp dispatch(reply, %State{} = state) do
    State.broadcast(state)
    {:reply, reply, state}
  end

  defp dispatch(%State{} = state) do
    State.broadcast(state)
    {:noreply, state}
  end

  # If something bad happens in this module it's usually non recoverable. 
  defp dispatch(_, {:error, reason}), do: dispatch({:error, reason})
  defp dispatch({:error, reason}) do
    Logger.error ">> encountered a fatal error in Authorization. "
    Farmbot.factory_reset
  end

  @spec try_log_in(State.t) :: {:ok, Token.t} | {:error, atom}
  defp try_log_in(%State{server: server, interim: %{email: email, pass: pass}})
  do
    with {:ok, pub_key} <- Auth.get_public_key(server),
         {:ok, secret}  <- Auth.encrypt(email, pass, pub_key),
          do: try_get_token(server, secret)
  end

  defp try_log_in(%State{server: server, secret: secret}) do
    try_get_token(server, secret)
  end

  @spec try_get_token(binary, binary) :: State.t | {:error, atom}
  defp try_get_token(server, secret) do
    case Auth.get_token_from_server(secret, server) do
      {:ok, token} ->
        new_state =
          %State{server: server, secret: secret,
                 token: Token.create!(token), interim: nil}
        save(new_state)
        new_state
      {:error, :bad_password} ->
        Logger.error ">> Got a bad password!"
        Farmbot.factory_reset
      {:error, reason} ->
        Logger.error ">> failed to authorize: #{inspect reason}"
        {:error, reason}
    end
  end

  @spec save(State.t) :: :ok | {:error, atom}
  defp save(%State{} = state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
  end
end
