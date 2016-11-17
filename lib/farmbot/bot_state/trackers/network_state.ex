defmodule Farmbot.BotState.Network do
  @moduledoc """
    I DONT KNOW WHAT IM DOING
  """
  defmodule State do
    @moduledoc false

    defstruct [
      connected?: false,
      connection: nil
    ]

    @type t :: %__MODULE__{
      connected?: boolean,
      connection: :ethernet | {String.t, String.t}
    }

    @spec broadcast(t) :: t
    def broadcast(%State{} = state) do
      GenServer.cast(Farmbot.BotState.Monitor, state)
      state
    end
  end

  use GenServer
  require Logger

  def init(_args) do
    NetMan.put_pid(__MODULE__)
    {:ok, State.broadcast(%State{})}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.warn("[#{__MODULE__}] UNHANDLED CALL!: #{inspect event}", [__MODULE__])
    dispatch :unhandled, state
  end

  def handle_cast({:connected, connection, ip_address}, %State{} = state) do
    # UPDATE CONFIGURATION WITH THE IP ADDRESS
    GenServer.cast(Farmbot.BotState.Authorization, :connected)
    dispatch %State{state | connected?: true, connection: connection}
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
