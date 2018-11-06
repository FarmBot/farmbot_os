defmodule Farmbot.AMQP.BotStateTransport do
  use GenServer
  use AMQP
  require Farmbot.Logger

  # Pushes a state tree every 5 seconds for good luck.
  @default_force_time_ms 5_000
  @default_error_retry_ms 100
  @exchange "amq.topic"

  defstruct [:conn, :chan, :bot, :state_cache]
  alias __MODULE__, as: State

  def force do
    GenServer.cast(__MODULE__, :force)
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([conn, jwt]) do
    Process.flag(:sensitive, true)
    initial_bot_state = Farmbot.BotState.subscribe()
    {:ok, chan} = AMQP.Channel.open(conn)
    :ok = Basic.qos(chan, global: true)
    {:ok, struct(State, conn: conn, chan: chan, bot: jwt.bot, state_cache: initial_bot_state), 0}
  end

  def handle_cast(:force, state) do
    {:noreply, state, 0}
  end

  def handle_info(:timeout, %{state_cache: bot_state} = state) do
    case push_bot_state(state.chan, state.bot, bot_state) do
      :ok ->
        {:noreply, state, @default_force_time_ms}
      error ->
        Farmbot.Logger.error 1, "Failed to dispatch BotState: #{inspect error}"
        {:noreply, state, @default_error_retry_ms}
    end
  end

  def handle_info({Farmbot.BotState, change}, state) do
    new_state_cache = Ecto.Changeset.apply_changes(change)
    {:noreply, %{state | state_cache: new_state_cache}, 0}
  end

  defp push_bot_state(chan, bot, %Farmbot.BotStateNG{} = bot_state) do
    json =
      bot_state
      |> Farmbot.BotStateNG.view()
      |> Farmbot.JSON.encode!()
    AMQP.Basic.publish(chan, @exchange, "bot.#{bot}.status", json)
  end
end
