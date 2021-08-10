defmodule FarmbotTelemetryTest do
  use ExUnit.Case
  doctest FarmbotTelemetry

  require FarmbotTelemetry

  test "uses :telemetry" do
    :ok = FarmbotTelemetry.attach_recv(:event, :test_subsystem, self())
    :ok = FarmbotTelemetry.event(:test_subsystem, :measurement, 1.0)

    assert_receive {[:farmbot_telemetry, :event, :test_subsystem],
                    %{measurement: :measurement, value: 1.0}, _meta, _config}
  end

  test "assigns meta" do
    :ok = FarmbotTelemetry.attach_recv(:event, :test_subsystem, self())

    :ok =
      FarmbotTelemetry.event(:test_subsystem, :measurement, 1.0, hello: "world")

    assert_receive {[:farmbot_telemetry, :event, :test_subsystem],
                    %{measurement: :measurement, value: 1.0}, meta, _config}

    assert meta[:hello] == "world"
  end

  test "consumes telemetry" do
    me = self()

    FarmbotTelemetry.consume_telemetry(fn
      {uuid, date, event, :test_subsystem, kind, value, meta} ->
        assert is_binary(uuid)
        assert %DateTime{} = date
        assert event == :event
        assert kind == :measurement
        assert value == 1.0
        %{file: _, function: _, line: _, module: _} = meta
        send(me, :ok)

      _ ->
        :ok
    end)

    assert_receive :ok, 5_000
  end
end
