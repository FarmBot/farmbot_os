defmodule FarmbotCeleryScript.SysCalls.Stubs do
  @moduledoc """
  SysCall implementation that doesn't do anything. Useful for tests.
  """
  @behaviour FarmbotCeleryScript.SysCalls

  require Logger

  @impl true
  def log(message), do: error(:log, [message])

  @impl true
  def sequence_init_log(message), do: error(:log, [message])

  @impl true
  def sequence_complete_log(message), do: error(:log, [message])

  @impl true
  def calibrate(axis), do: error(:calibrate, [axis])

  @impl true
  def change_ownership(email, secret, server),
    do: error(:change_ownership, [email, secret, server])

  @impl true
  def check_update(), do: error(:check_update, [])

  @impl true
  def coordinate(x, y, z), do: error(:coordinate, [x, y, z])

  @impl true
  def dump_info(), do: error(:dump_info, [])

  @impl true
  def emergency_lock(), do: error(:emergency_lock, [])

  @impl true
  def emergency_unlock(), do: error(:emergency_unlock, [])

  @impl true
  def execute_script(package, args), do: error(:execute_script, [package, args])

  @impl true
  def update_farmware(package), do: error(:update_farmware, [package])

  @impl true
  def factory_reset(package), do: error(:factory_reset, [package])

  @impl true
  def find_home(axis), do: error(:find_home, [axis])

  @impl true
  def firmware_reboot(), do: error(:firmware_reboot, [])

  @impl true
  def flash_firmware(package), do: error(:flash_firmware, [package])

  @impl true
  def get_current_x(), do: error(:get_current_x, [])

  @impl true
  def get_current_y(), do: error(:get_current_y, [])

  @impl true
  def get_current_z(), do: error(:get_current_z, [])

  @impl true
  def get_sequence(resource_id), do: error(:get_sequence, [resource_id])

  @impl true
  def get_toolslot_for_tool(resource_id), do: error(:get_toolslot_for_tool, [resource_id])

  @impl true
  def home(axis, speed), do: error(:home, [axis, speed])

  @impl true
  def install_first_party_farmware(), do: error(:install_first_party_farmware, [])

  @impl true
  def move_absolute(x, y, z, speed), do: error(:move_absolute, [x, y, z, speed])

  @impl true
  def named_pin(named_pin_type, resource_id), do: error(:named_pin, [named_pin_type, resource_id])

  @impl true
  def nothing(), do: error(:nothing, [])

  @impl true
  def point(point_type, resource_id), do: error(:point, [point_type, resource_id])

  @impl true
  def power_off(), do: error(:power_off, [])

  @impl true
  def read_pin(pin_num, pin_mode), do: error(:read_pin, [pin_num, pin_mode])

  @impl true
  def read_status(), do: error(:read_status, [])

  @impl true
  def reboot(), do: error(:reboot, [])

  @impl true
  def resource_update(kind, resource_id, data),
    do: error(:resource_update, [kind, resource_id, data])

  @impl true
  def send_message(type, message, channels), do: error(:send_message, [type, message, channels])

  @impl true
  def set_servo_angle(pin, value), do: error(:set_servo_angle, [pin, value])

  @impl true
  def set_pin_io_mode(pin, mode), do: error(:set_pin_io_mode, [pin, mode])

  @impl true
  def set_user_env(env_name, env_value), do: error(:set_user_env, [env_name, env_value])

  @impl true
  def sync(), do: error(:sync, [])

  @impl true
  def wait(millis), do: error(:wait, [millis])

  @impl true
  def write_pin(pin_num, pin_mode, pin_value),
    do: error(:write_pin, [pin_num, pin_mode, pin_value])

  @impl true
  def zero(axis), do: error(:zero, [axis])

  defp error(fun, _args) do
    msg = """
    CeleryScript syscall stubbed: #{fun}
    """

    Logger.error(msg)
    {:error, msg}
  end
end
