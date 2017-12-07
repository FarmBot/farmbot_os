defmodule Farmbot.FirmwareTest do
  use ExUnit.Case, async: false
  alias Farmbot.Firmware
  alias Firmware.Vec3

  @default_speed_x 100
  @default_speed_y 100
  @default_speed_z 100

  @moduletag :farmbot_firmware

  test "moves to a location" do
    res = Firmware.move_absolute(vec3(100, 200, 300), @default_speed_x, @default_speed_y, @default_speed_z)
    assert match?(:ok, res)
    assert match?(%{x: 100, y: 200, z: 300}, Farmbot.BotState.get_current_pos())
  end

  test "emergency locks and unlocks the bot" do
    Firmware.emergency_lock
    assert Farmbot.BotState.locked?()

    Firmware.emergency_unlock()
    refute Farmbot.BotState.locked?()
  end

  test "locks the bot, and makes sure more commands are disaloud" do
    Firmware.emergency_lock

    res = Firmware.move_absolute(vec3(100, 200, 300), @default_speed_x, @default_speed_y, @default_speed_z)
    assert match?({:error, :firmware_error}, res)

    Firmware.emergency_unlock
  end

  test "homes an axis" do
    Firmware.move_absolute(vec3(100, 200, 300), @default_speed_x, @default_speed_y, @default_speed_z)
    res_x = Firmware.home(:x, @default_speed_x)
    assert match?(:ok, res_x)
    assert match?(%{x: 0, y: 200, z: 300}, Farmbot.BotState.get_current_pos())

    res_y = Firmware.home(:y, @default_speed_y)
    assert match?(:ok, res_y)
    assert match?(%{x: 0, y: 0, z: 300}, Farmbot.BotState.get_current_pos())

    res_z = Firmware.home(:z, @default_speed_y)
    assert match?(:ok, res_z)
    assert match?(%{x: 0, y: 0, z: 0}, Farmbot.BotState.get_current_pos())
  end

  test "updates a param" do
    res = Firmware.update_param(:encoder_scaling_x, 123)
    assert match?(:ok, res)
    assert Farmbot.BotState.get_param(:encoder_scaling_x) == 123
  end

  defp vec3(x, y, z) do
    struct(Vec3, [x: x, y: y, z: z])
  end

end
