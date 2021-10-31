defmodule FarmbotOS.Firmware.GCodeDecoderTest do
  use ExUnit.Case
  alias FarmbotOS.Firmware.GCodeDecoder

  @fake_txt [
    "R00 Q0",
    "R81 XA1 XB1 YA1 YB1 ZA1 ZB1 Q0",
    "R82 X0.00 Y0.00 Z0.00 Q0",
    "R84 X0.00 Y0.00 Z0.00 Q0",
    "R85 X0 Y0 Z0 Q0",
    "R88 Q0",
    "R99 ARDUINO STARTUP COMPLETE",
    "R00 Q0",
    "R81 XA1 XB1 YA1 YB1 ZA1 ZB1 Q0",
    "R82 X0.00 Y0.00 Z0.00 Q0",
    "R84 X0.00 Y0.00 Z0.00 Q0",
    "R85 X0 Y0 Z0 Q0",
    "R88 Q0",
    "R99 ARDUINO STARTUP COMPLETE"
  ]

  test "empty input" do
    assert [] == GCodeDecoder.run([])
  end

  test "normal input" do
    expected = [
      idle: %{queue: 0.0},
      end_stops_report: %{queue: 0.0, z_endstop_a: 1.0, z_endstop_b: 1.0},
      current_position: %{queue: 0.0, x: 0.0, y: 0.0, z: 0.0},
      encoder_position_scaled: %{queue: 0.0, x: 0.0, y: 0.0, z: 0.0},
      encoder_position_raw: %{queue: 0.0, x: 0.0, y: 0.0, z: 0.0},
      not_configured: %{queue: 0.0},
      debug_message: "ARDUINO STARTUP COMPLETE",
      idle: %{queue: 0.0},
      end_stops_report: %{queue: 0.0, z_endstop_a: 1.0, z_endstop_b: 1.0},
      current_position: %{queue: 0.0, x: 0.0, y: 0.0, z: 0.0},
      encoder_position_scaled: %{queue: 0.0, x: 0.0, y: 0.0, z: 0.0},
      encoder_position_raw: %{queue: 0.0, x: 0.0, y: 0.0, z: 0.0},
      not_configured: %{queue: 0.0},
      debug_message: "ARDUINO STARTUP COMPLETE"
    ]

    assert expected == GCodeDecoder.run(@fake_txt)
  end

  test "negative numbers" do
    expected = [
      encoder_position_scaled: %{queue: 0.0, x: 0.2, y: 0.2, z: -123.4}
    ]

    assert expected == GCodeDecoder.run(["R84 X0.20 Y0.20 Z-123.4 Q0"])
  end
end
