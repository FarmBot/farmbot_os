defmodule FarmbotExt.AMQP.BotStateTransport do
  @moduledoc """
  Responsible for broadcasting the bot state tree over AMQP/MQTT
  """

  use GenServer
  use AMQP
  alias AMQP.Channel

  require FarmbotCore.Logger
  alias FarmbotCore.{BotState, BotStateNG, JSON}

  alias FarmbotExt.AMQP.ConnectionWorker

  # Pushes a state tree every 5 seconds for good luck.
  @default_force_time_ms 5_000
  @default_error_retry_ms 100
  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt, :state_cache]
  alias __MODULE__, as: State

  def force do
    GenServer.cast(__MODULE__, :force)
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    jwt = Keyword.fetch!(args, :jwt)
    Process.flag(:sensitive, true)
    {:ok, %State{conn: nil, chan: nil, jwt: jwt, state_cache: nil}, 0}
  end

  def terminate(reason, state) do
    FarmbotCore.Logger.error(1, "Disconnected from BotState channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: Channel.close(state.chan)
  end

  def handle_cast(:force, state) do
    {:noreply, state, 0}
  end

  def handle_info(:timeout, %{state_cache: nil} = state) do
    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true) do
      initial_bot_state = BotState.subscribe()
      {:noreply, %{state | conn: conn, chan: chan, state_cache: initial_bot_state}, 0}
    else
      nil ->
        {:noreply, %{state | conn: nil, chan: nil, state_cache: nil}, 5000}

      err ->
        FarmbotCore.Logger.error(1, "Failed to connect to BotState channel: #{inspect(err)}")
        {:noreply, %{state | conn: nil, chan: nil, state_cache: nil}, 1000}
    end
  end

  def handle_info(:timeout, %{state_cache: %{} = bot_state, chan: %{}} = state) do
    case push_bot_state(state.chan, state.jwt.bot, bot_state) do
      :ok ->
        {:noreply, state, @default_force_time_ms}

      error ->
        FarmbotCore.Logger.error(1, "Failed to dispatch BotState: #{inspect(error)}")
        {:noreply, state, @default_error_retry_ms}
    end
  end

  def handle_info({BotState, change}, state) do
    new_state_cache = Ecto.Changeset.apply_changes(change)
    {:noreply, %{state | state_cache: new_state_cache}, 0}
  end

  defp push_bot_state(chan, bot, %BotStateNG{} = bot_state) do
    json =
      bot_state
      |> BotStateNG.view()
      |> JSON.encode!()

    Basic.publish(chan, @exchange, "bot.#{bot}.status", json)
  end
end
