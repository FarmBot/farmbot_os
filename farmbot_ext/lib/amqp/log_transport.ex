defmodule Farmbot.AMQP.LogTransport do
  use GenServer
  use AMQP
  require Farmbot.Logger
  require Logger
  import Farmbot.Config, only: [update_config_value: 4]

  @exchange "amq.topic"
  @checkup_ms 100

  defstruct [:conn, :chan, :bot, :state_cache]
  alias __MODULE__, as: State

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([conn, jwt]) do
    Process.flag(:sensitive, true)
    initial_bot_state = Farmbot.BotState.subscribe()
    {:ok, chan} = AMQP.Channel.open(conn)
    :ok = Basic.qos(chan, global: true)
    state = struct(State, conn: conn, chan: chan, bot: jwt.bot, state_cache: initial_bot_state)
    {:ok, state, 0}
  end

  def terminate(reason, state) do
    ok_reasons = [:normal, :shutdown, :token_refresh]
    update_config_value(:bool, "settings", "ignore_fbos_config", false)

    if reason not in ok_reasons do
      Farmbot.Logger.error(1, "Logger amqp client Died: #{inspect(reason)}")
      update_config_value(:bool, "settings", "log_amqp_connected", true)
    end

    # If a channel was still open, close it.
    if state.chan, do: AMQP.Channel.close(state.chan)
  end

  def handle_info({Farmbot.BotState, change}, state) do
    new_state_cache = Ecto.Changeset.apply_changes(change)
    {:noreply, %{state | state_cache: new_state_cache}, @checkup_ms}
  end

  def handle_info(:timeout, state) do
    {:noreply, state, {:continue, Farmbot.Logger.handle_all_logs()}}
  end

  def handle_continue([log | rest], state) do
    case do_handle_log(log, state) do
      :ok ->
        IO.puts "handled log: #{log.id}"
        {:noreply, state, {:continue, rest}}
      error ->
        Logger.error("Logger amqp client failed to upload log: #{inspect error}")
        # Reschedule log to be uploaded again
        Farmbot.Logger.insert_log!(log)
        {:noreply,  state, @checkup_ms}
    end
  end

  def handle_continue([], state) do
    {:noreply, state, @checkup_ms}
  end

  defp do_handle_log(log, state) do
    if Farmbot.Logger.should_log?(log.module, log.verbosity) do
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
        #QUESTION(Connor) - Why does this need `.to_unix()`?
        #ANSWER(Connor) - because the FE needed it.
        created_at: DateTime.from_naive!(log.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
        channels: log.meta[:channels] || [],
        message: log.message
      }

      json_log = add_position_to_log(log_without_pos, location_data)
      push_bot_log(state.chan, state.bot, json_log)
    end
  end

  defp push_bot_log(chan, bot, log) do
    json = Farmbot.JSON.encode!(log)
    :ok = AMQP.Basic.publish(chan, @exchange, "bot.#{bot}.logs", json)
  end

  defp add_position_to_log(%{} = log, %{position: %{x: x, y: y, z: z}}) do
    Map.merge(log, %{x: x, y: y, z: z})
  end
end
