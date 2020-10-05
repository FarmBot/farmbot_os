defmodule FarmbotExt.AMQP.TelemetryChannel do
  @moduledoc """
  Channel that dispatches telemetry messgaes out of the
  DETS database.
  """

  use GenServer
  use AMQP

  alias FarmbotCore.{BotState, BotStateNG}
  alias FarmbotExt.AMQP.ConnectionWorker
  alias FarmbotExt.AMQP.Support
  require FarmbotCore.Logger
  require FarmbotTelemetry

  @exchange "amq.topic"
  @dispatch_metrics_timeout 300_000
  @consume_telemetry_timeout 1000

  defstruct [:conn, :chan, :jwt, :cache]
  alias __MODULE__, as: State

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    jwt = Keyword.fetch!(args, :jwt)
    send(self(), :connect_amqp)
    cache = BotState.subscribe()

    state = %State{
      conn: nil,
      chan: nil,
      jwt: jwt,
      cache: cache
    }

    {:ok, state}
  end

  def terminate(reason, state) do
    FarmbotCore.Logger.error(1, "Disconnected from Telemetry channel: #{inspect(reason)}")
    if state.chan, do: ConnectionWorker.close_channel(state.chan)
  end

  def handle_info(:connect_amqp, state) do
    bot = state.jwt.bot
    telemetry = bot <> "_telemetry"

    with {:ok, {conn, chan}} <- Support.create_channel(),
         {:ok, _} <- Queue.declare(chan, telemetry, auto_delete: true),
         {:ok, _} <- Queue.purge(chan, telemetry) do
      FarmbotTelemetry.event(:amqp, :channel_open)
      FarmbotCore.Logger.debug(3, "connected to Telemetry channel")
      send(self(), :consume_telemetry)
      send(self(), :dispatch_metrics)
      {:noreply, %{state | conn: conn, chan: chan}}
    else
      nil ->
        Process.send_after(self(), :connect_amqp, 5000)
        {:noreply, %{state | conn: nil, chan: nil}}

      err ->
        FarmbotCore.Logger.error(1, "Failed to connect to Telemetry channel: #{inspect(err)}")
        FarmbotTelemetry.event(:amqp, :channel_open_error, nil, error: inspect(err))
        Process.send_after(self(), :connect_amqp, 2000)
        {:noreply, %{state | conn: nil, chan: nil}}
    end
  end

  def handle_info({BotState, change}, state) do
    cache = Ecto.Changeset.apply_changes(change)
    {:noreply, %{state | cache: cache}}
  end

  def handle_info(:dispatch_metrics, state) do
    metrics = BotStateNG.view(state.cache).informational_settings

    json =
      FarmbotCore.JSON.encode!(%{
        "telemetry_captured_at" => DateTime.utc_now(),
        "telemetry_soc_temp" => metrics.soc_temp,
        "telemetry_throttled" => metrics.throttled,
        "telemetry_wifi_level" => metrics.wifi_level,
        "telemetry_wifi_level_percent" => metrics.wifi_level_percent,
        "telemetry_uptime" => metrics.uptime,
        "telemetry_memory_usage" => metrics.memory_usage,
        "telemetry_disk_usage" => metrics.disk_usage,
        "telemetry_scheduler_usage" => metrics.scheduler_usage,
        "telemetry_cpu_usage" => metrics.cpu_usage,
        "telemetry_target" => metrics.target
      })

    Basic.publish(state.chan, @exchange, "bot.#{state.jwt.bot}.telemetry", json)
    Process.send_after(self(), :dispatch_metrics, @dispatch_metrics_timeout)
    {:noreply, state}
  end

  def handle_info(:consume_telemetry, state) do
    _ =
      FarmbotTelemetry.consume_telemetry(fn
        {uuid, captured_at, kind, subsystem, measurement, value, meta} ->
          json =
            FarmbotCore.JSON.encode!(%{
              "telemetry.uuid" => uuid,
              "telemetry.measurement" => measurement,
              "telemetry.value" => value,
              "telemetry.kind" => kind,
              "telemetry.subsystem" => subsystem,
              "telemetry.captured_at" => to_string(captured_at),
              "telemetry.meta" => %{meta | function: inspect(meta.function)}
            })

          Basic.publish(state.chan, @exchange, "bot.#{state.jwt.bot}.telemetry", json)
      end)

    _ = Process.send_after(self(), :consume_telemetry, @consume_telemetry_timeout)
    {:noreply, state}
  end
end
