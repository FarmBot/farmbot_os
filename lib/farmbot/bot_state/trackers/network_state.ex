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
    {:ok, SafeStorage.read(__MODULE__) |> load |> State.broadcast}
  end

  @spec load({:ok, State.t}) :: State.t
  defp load({:ok, %State{} = state}) do
    NetMan.connect(state.connection, __MODULE__)
    state
  end

  @spec load(any) :: State.t
  defp load(_), do: %State{}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.warn("[#{__MODULE__}] UNHANDLED CALL!: #{inspect event}", [__MODULE__])
    dispatch :unhandled, state
  end

  def handle_cast({:connected, connection, ip_address}, %State{} = state) do
    GenServer.cast(Farmbot.BotState.Configuration,
                  {:update_info, :private_ip, ip_address})
    GenServer.cast(Farmbot.BotState.Authorization, :try_log_in)
    new_state = %State{state | connected?: true, connection: connection}
    Farmbot.node_reset(ip_address)
    Process.sleep(2000)
    # Putting a sleep in a GenServer cast because #swag
    save new_state
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

  @spec save(State.t) :: :ok | {:error, atom}
  defp save(%State{} = state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
  end
end
