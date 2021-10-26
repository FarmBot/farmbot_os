defmodule FarmbotCore.Celery.Corpus.NodeTest do
  use ExUnit.Case
  alias FarmbotCore.Celery.Corpus

  test "inspect" do
    a =
      "Sequence(version, locals) [assertion, calibrate, change_ownership, check_updates, emergency_lock, emergency_unlock, execute, execute_script, factory_reset, find_home, flash_firmware, home, _if, move_absolute, move_relative, move, power_off, read_pin, read_status, reboot, update_resource, send_message, set_servo_angle, set_user_env, sync, take_photo, toggle_pin, wait, write_pin, zero]"

    b = inspect(Corpus.sequence())
    assert a == b
  end
end
