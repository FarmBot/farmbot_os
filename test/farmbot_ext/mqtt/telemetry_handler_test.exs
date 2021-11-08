defmodule FarmbotOS.MQTT.TelemetryHandlerTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.BotStateNG
  alias FarmbotOS.JSON
  alias FarmbotOS.MQTT
  alias FarmbotOS.MQTT.TelemetryHandler, as: T

  import ExUnit.CaptureLog

  test "unknown messages" do
    log = capture_log(fn -> T.handle_info(:misc, %{}) end)

    assert log =~ "FarmbotOS.MQTT.TelemetryHandler Uncaught message: :misc"
  end

  # I don't like this test.
  # Consider refactoring if problems arise.
  test "consume_telemetry" do
    state = %T{cache: BotStateNG.new(), client_id: "testsuite"}

    expect(FarmbotTelemetry, :consume_telemetry, 1, fn cb ->
      _ =
        cb.({
          :uuid,
          :captured_at,
          :kind,
          :subsystem,
          :measurement,
          :value,
          %{function: "¯\_(ツ)_/¯"}
        })
    end)

    expect(FarmbotOS.Time, :send_after, 1, fn pid, msg, timeout ->
      assert pid == self()
      assert msg == :consume_telemetry
      assert timeout == 1000
    end)

    expect(MQTT, :publish, 1, fn
      client_id, topic, payload ->
        assert topic == "bot/#{state.username}/telemetry"
        assert client_id == state.client_id
        json = JSON.decode!(payload)

        assert json == %{
                 "telemetry.captured_at" => "captured_at",
                 "telemetry.kind" => "kind",
                 "telemetry.measurement" => "measurement",
                 "telemetry.meta" => %{"function" => "\"¯_(ツ)_/¯\""},
                 "telemetry.subsystem" => "subsystem",
                 "telemetry.uuid" => "uuid",
                 "telemetry.value" => "value"
               }
    end)

    T.handle_info(:consume_telemetry, state)
  end

  test ":dispatch_metrics" do
    state = %T{cache: BotStateNG.new(), client_id: "testsuite"}

    expect(MQTT, :publish, 1, fn
      client_id, topic, payload ->
        assert topic == "bot/#{state.username}/telemetry"
        assert client_id == state.client_id
        json = JSON.decode!(payload)
        _ = Map.fetch!(json, "telemetry_captured_at")
        _ = Map.fetch!(json, "telemetry_cpu_usage")
        _ = Map.fetch!(json, "telemetry_disk_usage")
        _ = Map.fetch!(json, "telemetry_memory_usage")
        _ = Map.fetch!(json, "telemetry_scheduler_usage")
        _ = Map.fetch!(json, "telemetry_soc_temp")
        _ = Map.fetch!(json, "telemetry_target")
        _ = Map.fetch!(json, "telemetry_throttled")
        _ = Map.fetch!(json, "telemetry_uptime")
        _ = Map.fetch!(json, "telemetry_wifi_level")
        _ = Map.fetch!(json, "telemetry_wifi_level_percent")
    end)

    expect(FarmbotOS.Time, :send_after, 1, fn pid, msg, timeout ->
      assert pid == self()
      assert msg == :dispatch_metrics
      assert timeout == 300_000
    end)

    result = T.handle_info(:dispatch_metrics, state)
    assert result == {:noreply, state}
  end
end
