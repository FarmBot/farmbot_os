defmodule Farmbot.AMQP.BotStateTransport do
  use GenServer
  use AMQP
  require Farmbot.Logger

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
    Farmbot.Registry.subscribe()
    {:ok, chan} = AMQP.Channel.open(conn)
    :ok = Basic.qos(chan, global: true)
    {:ok, struct(State, conn: conn, chan: chan, bot: jwt.bot)}
  end

  def handle_cast(:force, %{state_cache: bot_state} = state) do
    push_bot_state(state.chan, state.bot, bot_state)
    {:noreply, state}
  end

  def handle_info(
        {Farmbot.Registry, {Farmbot.BotState, bot_state}},
        %{state_cache: bot_state} = state
      ) do
    # IO.puts "no state change"
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, {Farmbot.BotState, bot_state}}, state) do
    # IO.puts "pushing state"
    state.state_cache
    cache = push_bot_state(state.chan, state.bot, bot_state)
    {:noreply, %{state | state_cache: cache}}
  end

  def handle_info({Farmbot.Registry, _}, state), do: {:noreply, state}

  defp push_bot_state(chan, bot, state) do
    json = Farmbot.JSON.encode!(state)
    :ok = AMQP.Basic.publish(chan, @exchange, "bot.#{bot}.status", json)
    state
  end
end
