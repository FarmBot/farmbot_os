defmodule FarmbotCore.Firmware.InboundSideEffectsTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias FarmbotCore.Firmware.InboundSideEffects

  @fake_state %FarmbotCore.Firmware.UARTCore{}

  test "Firmware debug logs" do
    msg = "Hello, world!"
    gcode = [{:debug_message, msg}]
    run = fn -> InboundSideEffects.process(@fake_state, gcode) end
    assert capture_log(run) =~ msg
  end

  test "Debug logging enabled" do
    s = %{@fake_state | logs_enabled: true}
    gcode = {:complete_homing_x, nil}
    run = fn -> InboundSideEffects.process(s, [gcode]) end
    assert capture_log(run) =~ inspect(gcode)
  end

  test "complete_homing_x|y|z" do
    gcode = [
      {:complete_homing_x, nil},
      {:complete_homing_y, nil},
      {:complete_homing_z, nil}
    ]

    results = InboundSideEffects.process(@fake_state, gcode)
    assert results == @fake_state
  end
end
