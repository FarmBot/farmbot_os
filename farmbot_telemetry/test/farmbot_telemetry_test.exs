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
    :ok = FarmbotTelemetry.event(:test_subsystem, :measurement, 1.0, hello: "world")

    assert_receive {[:farmbot_telemetry, :event, :test_subsystem],
                    %{measurement: :measurement, value: 1.0}, meta, _config}

    assert meta[:hello] == "world"
  end
end
