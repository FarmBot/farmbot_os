defmodule FarmbotCeleryScript.Corpus.NodeTest do
  use ExUnit.Case, async: true
  alias FarmbotCeleryScript.Corpus

  test "inspect" do
    a =
      "Sequence(version, locals) [assertion, calibrate, change_ownership, check_updates, emergency_lock, emergency_unlock, execute, execute_script, factory_reset, find_home, flash_firmware, home, install_farmware, install_first_party_farmware, _if, move_absolute, move_relative, power_off, read_pin, read_status, reboot, remove_farmware, update_resource, send_message, set_servo_angle, set_user_env, sync, take_photo, toggle_pin, update_farmware, wait, write_pin, zero]"

    b = inspect(Corpus.sequence())
    assert a == b
  end
end
