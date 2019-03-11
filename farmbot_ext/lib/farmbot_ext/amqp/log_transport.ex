defmodule FarmbotExt.AMQP.LogTransport do
  use GenServer
  use AMQP
  alias AMQP.Channel

  alias FarmbotCore.{BotState, JSON}
  require FarmbotCore.Logger

  alias FarmbotExt.AMQP.ConnectionWorker
  require Logger

  @exchange "amq.topic"
  @checkup_ms 100

  defstruct [:conn, :chan, :jwt, :state_cache]
  alias __MODULE__, as: State

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
    FarmbotCore.Logger.error(1, "Disconnected from Log channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: Channel.close(state.chan)
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
        FarmbotCore.Logger.error(1, "Failed to connect to Log channel: #{inspect(err)}")
        {:noreply, %{state | conn: nil, chan: nil, state_cache: nil}, 1000}
    end
  end

  def handle_info(:timeout, state) do
    {:noreply, state, {:continue, FarmbotCore.Logger.handle_all_logs()}}
  end

  def handle_info({BotState, change}, state) do
    new_state_cache = Ecto.Changeset.apply_changes(change)
    {:noreply, %{state | state_cache: new_state_cache}, @checkup_ms}
  end

  def handle_continue([log | rest], state) do
    case do_handle_log(log, state) do
      :ok ->
        {:noreply, state, {:continue, rest}}

      error ->
        Logger.error("Logger amqp client failed to upload log: #{inspect(error)}")
        # Reschedule log to be uploaded again
        FarmbotCore.Logger.insert_log!(log)
        {:noreply, state, @checkup_ms}
    end
  end

  def handle_continue([], state) do
    {:noreply, state, @checkup_ms}
  end

  defp do_handle_log(log, state) do
    if FarmbotCore.Logger.should_log?(log.module, log.verbosity) do
      fb = %{position: %{x: -1, y: -1, z: -1}}
      location_data = Map.get(state.state_cache || %{}, :location_data, fb)

      log_without_pos = %{
        type: log.level,
        x: nil,
        y: nil,
        z: nil,
        verbosity: log.verbosity,
        major_version: log.version.major,
        minor_version: log.version.minor,
        patch_version: log.version.patch,
        # QUESTION(Connor) - Why does this need `.to_unix()`?
        # ANSWER(Connor) - because the FE needed it.
        created_at: DateTime.from_naive!(log.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
        channels: log.meta[:channels] || [],
        message: log.message
      }

      json_log = add_position_to_log(log_without_pos, location_data)
      push_bot_log(state.chan, state.jwt.bot, json_log)
    else
      :ok
    end
  end

  defp push_bot_log(chan, bot, log) do
    json = JSON.encode!(log)
    :ok = Basic.publish(chan, @exchange, "bot.#{bot}.logs", json)
  end

  defp add_position_to_log(%{} = log, %{position: %{x: x, y: y, z: z}}) do
    Map.merge(log, %{x: x, y: y, z: z})
  end
end
