defmodule FarmbotTelemetryTest do
  use ExUnit.Case
  doctest FarmbotTelemetry
  require FarmbotTelemetry

  test "uses :telemetry" do
    :ok = FarmbotTelemetry.attach_recv(:event, :test_subsystem, self())
    :ok = FarmbotTelemetry.event(:test_subsystem, :measurement, 1.0)

    assert_receive {[:farmbot, :event, :test_subsystem],
                    %{measurement: :measurement, value: 1.0}, _meta, _config}
  end

  test "assigns meta" do
    :ok = FarmbotTelemetry.attach_recv(:event, :test_subsystem, self())

    :ok =
      FarmbotTelemetry.event(:test_subsystem, :measurement, 1.0, hello: "world")

    assert_receive {[:farmbot, :event, :test_subsystem],
                    %{measurement: :measurement, value: 1.0}, meta, _config}

    assert meta[:hello] == "world"
  end

  test "telemetry_meta" do
    result = FarmbotTelemetry.telemetry_meta(__ENV__, %{})
    assert String.contains?(result.file, "farmbot_telemetry_test.exs")
    assert result.function == {:"test telemetry_meta", 1}
    assert is_number(result.line)
    assert result.module == FarmbotTelemetryTest
  end

  test "event (unknown params)" do
    # This test is terrible.
    # If anyone want to refactor this, have at it. RC.
    boom = fn ->
      Code.eval_string("""
      require FarmbotTelemetry
      FarmbotTelemetry.event(\"?\", \"?\", \"?\", \"?\")
      """)
    end

    assert_raise Mix.Error, boom
  end
end
