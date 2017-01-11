defmodule Farmbot.Serial.HandlerTest do
  # this is set async false because all the commands coming over the serial line
  # Will only ever be one at a time
  use ExUnit.Case, async: false
  def fix_race, do: Process.sleep(10)
  
  # def send_fake_msg(msg) do
  #   GenServer.cast(Nerves.FakeUART, {:fake_message, msg<>"\r\n"})
  # end
  #
  # def set_param(param, value) do
  #   send_fake_msg("R21 P#{param} V#{value}")
  # end

  # test "sets position" do
  #   send_fake_msg("R82 X-20 Y0 Z0")
  #   # Just pretend this isnt here
  #   fix_race
  #   pos = Farmbot.BotState.get_current_pos
  #   assert(pos == [-20,0,0])
  # end
  #
  # test "sets some params" do
  #   set_param("0", 123)
  #   set_param("103", 1)
  #   set_param("32", 0)
  #
  #   fix_race # shhhh
  #
  #   version = Farmbot.BotState.get_fw_version
  #   assert(version == 123)
  #
  #   # 103
  #   zencen = Farmbot.BotState.get_param :encoder_enabled_z
  #   assert(zencen == 1)
  #
  #   # 32
  #   whatever = Farmbot.BotState.get_param :movement_invert_motor_y
  #   assert(whatever == 0)
  # end
end
