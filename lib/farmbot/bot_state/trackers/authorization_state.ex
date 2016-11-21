defmodule Farmbot.BotState.Authorization do
  defmodule State do
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

  use GenServer
  require Logger
  def init(_args) do
    {:ok, SafeStorage.read(__MODULE__)
          |> load
          |> maybe_get_token(Farmbot.Auth.get_token)
          |> State.broadcast}
  end

  @spec load({:ok, State.t} | nil) :: State.t
  defp load({:ok, %State{} = state}), do: state
  defp load(nil), do: %State{}

  @spec maybe_get_token(State.t, {:ok, Token.t} | nil) :: State.t
  defp maybe_get_token(%State{} = state, {:ok, token}) do
    %State{state | token: Token.create(token)}
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

  def handle_call(event, _from, %State{} = state) do
    Logger.warn("[#{__MODULE__}] UNHANDLED CALL!: #{inspect event}", [__MODULE__])
    dispatch :unhandled, state
  end

  # I CAN DO BETTER
  def handle_cast(:try_log_in, %State{} = state) do
    dispatch try_log_in(state)
  end

  # We have to store these temporarily in case the bot doesnt have network yet.
  def handle_cast({:creds, {email, pass, server}}, %State{} = _state) do
    new_state = %State{server: server, interim: %{ email: email,
                                                   pass: pass } }
    dispatch new_state
  end

  def handle_cast(event, %State{} = state) do
    Logger.warn("[#{__MODULE__}] UNHANDLED CAST!: #{inspect event}", [__MODULE__])
    dispatch state
  end

  defp dispatch(reply, %State{} = state) do
    State.broadcast(state)
    {:reply, reply, state}
  end

  defp dispatch(%State{} = state) do
    State.broadcast(state)
    {:noreply, state}
  end

  @spec try_log_in(State.t) :: {:ok, Token.t} | {:error, atom}
  defp try_log_in(%State{server: server, interim: %{email: email, pass: pass}}) do
    with {:ok, pub_key} <- Farmbot.Auth.get_public_key(server),
         {:ok, secret } <- Farmbot.Auth.encrypt(email, pass, pub_key),
         do: try_get_token(server, secret)
  end

  defp try_log_in(%State{server: server, secret: secret}) do
    try_get_token(server, secret)
  end

  @spec try_get_token(binary, binary) :: State.t | {:error, atom}
  defp try_get_token(server, secret) do
    case Farmbot.Auth.get_token_from_server(secret, server) do
      {:ok, token} ->
        new_state = %State{server: server, secret: secret, token: Token.create(token), interim: nil}
        save(new_state)
        new_state
      {:error, :bad_password} ->
        Farmbot.factory_reset
      {:error, reason} ->
        Logger.error("AUTH FAILED!: #{inspect reason}")
        {:error, reason}
    end
  end

  @spec save(State.t) :: :ok | {:error, atom}
  defp save(%State{} = state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
  end

end
