defmodule FarmbotOS.MQTT.TelemetryHandler do
  use GenServer

  require FarmbotOS.Logger
  require FarmbotTelemetry
  require Logger

  alias __MODULE__, as: State
  alias FarmbotOS.{BotState, BotStateNG}
  alias FarmbotOS.MQTT

  @consume_telemetry_timeout 1000
  @dispatch_metrics_timeout 300_000
  defstruct [:cache, :client_id, :username]

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    state = %State{
      client_id: Keyword.fetch!(args, :client_id),
      username: Keyword.fetch!(args, :username),
      cache: BotState.subscribe()
    }

    send(self(), :consume_telemetry)
    send(self(), :dispatch_metrics)
    {:ok, state}
  end

  def handle_info({BotState, change}, state) do
    {:noreply, %{state | cache: Ecto.Changeset.apply_changes(change)}}
  end

  def handle_info(:dispatch_metrics, state) do
    metrics = BotStateNG.view(state.cache).informational_settings

    json =
      FarmbotOS.JSON.encode!(%{
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

    publish(state, json)

    FarmbotOS.Time.send_after(
      self(),
      :dispatch_metrics,
      @dispatch_metrics_timeout
    )

    {:noreply, state}
  end

  def handle_info(:consume_telemetry, state) do
    _ =
      FarmbotTelemetry.consume_telemetry(fn
        {uuid, captured_at, kind, subsystem, measurement, value, meta} ->
          json =
            FarmbotOS.JSON.encode!(%{
              "telemetry.uuid" => uuid,
              "telemetry.measurement" => measurement,
              "telemetry.value" => value,
              "telemetry.kind" => kind,
              "telemetry.subsystem" => subsystem,
              "telemetry.captured_at" => to_string(captured_at),
              "telemetry.meta" => %{meta | function: inspect(meta.function)}
            })

          publish(state, json)
      end)

    _ =
      FarmbotOS.Time.send_after(
        self(),
        :consume_telemetry,
        @consume_telemetry_timeout
      )

    {:noreply, state}
  end

  def handle_info(req, state) do
    Logger.info("#{inspect(__MODULE__)} Uncaught message: #{inspect(req)}")
    {:noreply, state}
  end

  def publish(state, payload) do
    MQTT.publish(state.client_id, "bot/#{state.username}/telemetry", payload)
  end
end
