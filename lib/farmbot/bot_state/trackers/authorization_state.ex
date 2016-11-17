defmodule Farmbot.BotState.Authorization do
  defmodule State do
    @type t :: %__MODULE__{
      token: map | nil,
      secret: nil | binary,
      server: nil,
      interim: nil | %{
        email: String.t,
        pass: String.t
      }
    }
    defstruct [
      token: nil,
      secret: nil,
      server: nil,
      interim: %{
        email: nil,
        pass: nil
      }
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
    {:ok, State.broadcast(%State{})}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.warn("[#{__MODULE__}] UNHANDLED CALL!: #{inspect event}", [__MODULE__])
    dispatch :unhandled, state
  end

  # def handle_cast(:connected, %State{} = state)
  # when state.interim |> is_nil or state.server |> is_nil
  # do
  #   Logger.error("AUTH STATE IS MESSED UP")
  # end

  # I CAN DO BETTER
  def handle_cast(:connected, %State{} = state) do
    # {:ok, pub_key}  <- get_public_key(server),
    #        {:ok, encryped} <- encrypt(email,pass,pub_key),
    #        do: get_token_from_server(encryped, server)
    with {:ok, pub_key} <- Farmbot.Auth.get_public_key(state.server),
         {:ok, secret } <- Farmbot.Auth.encrypt(state.interim.email, state.interim.pass, pub_key),
         {:ok, token  } <- Farmbot.Auth.get_token_from_server(secret, state.server),
    do: dispatch %State{state | interim: nil, token: token, secret: secret}
  end

  def handle_cast({:creds, {email, pass, server}}, %State{} = state) do
    new_state = %State{state | interim: %{ email: email,
                                           pass: pass },
                               token: nil,
                               server: server}
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
end
