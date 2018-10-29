defmodule Farmbot.AMQP.LogTransport do
  use GenServer
  use AMQP
  require Farmbot.Logger
  import Farmbot.Config, only: [update_config_value: 4]

  @exchange "amq.topic"

  defstruct [:conn, :chan, :bot, :state_cache]
  alias __MODULE__, as: State

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([conn, jwt]) do
    Process.flag(:sensitive, true)
    Farmbot.Registry.subscribe()
    {:ok, chan} = AMQP.Channel.open(conn)
    :ok = Basic.qos(chan, global: true)
    state = struct(State, conn: conn, chan: chan, bot: jwt.bot)

    for l <- Farmbot.Logger.handle_all_logs() do
      do_handle_log(l, state)
    end

    {:ok, state}
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

  def handle_info({Farmbot.Registry, {Farmbot.Logger, {:log_ready, id}}}, state) do
    if log = Farmbot.Logger.handle_log(id) do
      do_handle_log(log, state)
    end

    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, {Farmbot.BotState, bot_state}}, state) do
    {:noreply, %{state | state_cache: bot_state}}
  end

  def handle_info({Farmbot.Registry, _}, state) do
    {:noreply, state}
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
        created_at: DateTime.from_naive!(log.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
        channels: log.meta[:channels] || [],
        message: log.message
      }

      log = add_position_to_log(log_without_pos, location_data)
      push_bot_log(state.chan, state.bot, log)
    end
  end

  defp push_bot_log(chan, bot, log) do
    json = Farmbot.JSON.encode!(log)
    :ok = AMQP.Basic.publish(chan, @exchange, "bot.#{bot}.logs", json)
  end

  defp add_position_to_log(%{} = log, %{position: %{} = pos}) do
    Map.merge(log, pos)
  end
end
