defmodule FarmbotCeleryScript.SysCalls.Stubs do
  @moduledoc """
  SysCall implementation that doesn't do anything. Useful for tests.
  """
  @behaviour FarmbotCeleryScript.SysCalls

  require Logger
  def calibrate(axis), do: error(:calibrate, [axis])

  def change_ownership(email, secret, server),
    do: error(:change_ownership, [email, secret, server])

  def check_update(), do: error(:check_update, [])

  def coordinate(x, y, z), do: error(:coordinate, [x, y, z])

  def dump_info(), do: error(:dump_info, [])

  def emergency_lock(), do: error(:emergency_lock, [])

  def emergency_unlock(), do: error(:emergency_unlock, [])

  def execute_script(package, args), do: error(:execute_script, [package, args])

  def factory_reset(), do: error(:factory_reset, [])

  def find_home(axis), do: error(:find_home, [axis])

  def firmware_reboot(), do: error(:firmware_reboot, [])

  def flash_firmware(package), do: error(:flash_firmware, [package])

  def get_current_x(), do: error(:get_current_x, [])

  def get_current_y(), do: error(:get_current_y, [])

  def get_current_z(), do: error(:get_current_z, [])

  def get_sequence(resource_id), do: error(:get_sequence, [resource_id])

  def get_toolslot_for_tool(resource_id), do: error(:get_toolslot_for_tool, [resource_id])

  def home(axis, speed), do: error(:home, [axis, speed])

  def install_first_party_farmware(), do: error(:install_first_party_farmware, [])

  def move_absolute(x, y, z, speed), do: error(:move_absolute, [x, y, z, speed])

  def named_pin(named_pin_type, resource_id), do: error(:named_pin, [named_pin_type, resource_id])

  def nothing(), do: error(:nothing, [])

  def point(point_type, resource_id), do: error(:point, [point_type, resource_id])

  def power_off(), do: error(:power_off, [])

  def read_pin(pin_num, pin_mode), do: error(:read_pin, [pin_num, pin_mode])

  def read_status(), do: error(:read_status, [])

  def reboot(), do: error(:reboot, [])

  def resource_update(kind, resource_id, data),
    do: error(:resource_update, [kind, resource_id, data])

  def send_message(type, message, channels), do: error(:send_message, [type, message, channels])

  def set_servo_angle(pin, value), do: error(:set_servo_angle, [pin, value])

  def set_user_env(env_name, env_value), do: error(:set_user_env, [env_name, env_value])

  def sync(), do: error(:sync, [])

  def wait(millis), do: error(:wait, [millis])

  def write_pin(pin_num, pin_mode, pin_value),
    do: error(:write_pin, [pin_num, pin_mode, pin_value])

  def zero(axis), do: error(:zero, [axis])

  defp error(fun, _args) do
    msg = """
    CeleryScript syscall stubbed: #{fun}
    """

    Logger.error(msg)
    {:error, msg}
  end
end
