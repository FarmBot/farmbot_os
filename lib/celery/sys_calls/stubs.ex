defmodule FarmbotOS.Celery.SysCallGlue.Stubs do
  @moduledoc """
  SysCall implementation that doesn't do anything. Useful for tests.
  """
  @behaviour FarmbotOS.Celery.SysCallGlue

  require Logger

  @impl true
  def log(message, force?), do: error(:log, [message, force?])

  @impl true
  def sequence_init_log(message), do: error(:log, [message])

  @impl true
  def sequence_complete_log(message), do: error(:log, [message])

  @impl true
  def calibrate(axis), do: error(:calibrate, [axis])

  @impl true
  def check_update(), do: error(:check_update, [])

  @impl true
  def coordinate(x, y, z), do: error(:coordinate, [x, y, z])

  @impl true
  def emergency_lock(), do: error(:emergency_lock, [])

  @impl true
  def emergency_unlock(), do: error(:emergency_unlock, [])

  @impl true
  def execute_script(package, args), do: error(:execute_script, [package, args])

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
  def get_cached_x(), do: error(:get_cached_x, [])

  @impl true
  def get_cached_y(), do: error(:get_cached_y, [])

  @impl true
  def get_cached_z(), do: error(:get_cached_z, [])

  @impl true
  def get_sequence(resource_id), do: error(:get_sequence, [resource_id])

  @impl true
  def get_toolslot_for_tool(resource_id),
    do: error(:get_toolslot_for_tool, [resource_id])

  @impl true
  def home(axis, speed), do: error(:home, [axis, speed])

  @impl true
  def move_absolute(x, y, z, speed), do: error(:move_absolute, [x, y, z, speed])

  @impl true
  def move_absolute(x, y, z, sx, sy, sz),
    do: error(:move_absolute, [x, y, z, sx, sy, sz])

  @impl true
  def named_pin(named_pin_type, resource_id),
    do: error(:named_pin, [named_pin_type, resource_id])

  @impl true
  def nothing(), do: error(:nothing, [])

  @impl true
  def point(point_type, resource_id),
    do: error(:point, [point_type, resource_id])

  @impl true
  def find_points_via_group(id), do: error(:find_points_via_group, [id])

  @impl true
  def power_off(), do: error(:power_off, [])

  @impl true
  def read_pin(pin_num, pin_mode), do: error(:read_pin, [pin_num, pin_mode])

  @impl true
  def read_cached_pin(pin_num), do: error(:read_cached_pin, [pin_num])

  @impl true
  def toggle_pin(pin_num), do: error(:toggle_pin, [pin_num])

  @impl true
  def read_status(), do: error(:read_status, [])

  @impl true
  def reboot(), do: error(:reboot, [])

  @impl true
  def send_message(type, message, channels),
    do: error(:send_message, [type, message, channels])

  @impl true
  def set_servo_angle(pin, value), do: error(:set_servo_angle, [pin, value])

  @impl true
  def set_pin_io_mode(pin, mode), do: error(:set_pin_io_mode, [pin, mode])

  @impl true
  def set_user_env(env_name, env_value),
    do: error(:set_user_env, [env_name, env_value])

  @impl true
  def sync(), do: error(:sync, [])

  @impl true
  def wait(millis), do: error(:wait, [millis])

  @impl true
  def write_pin(pin_num, pin_mode, pin_value),
    do: error(:write_pin, [pin_num, pin_mode, pin_value])

  @impl true
  def update_resource(kind, id, params),
    do: error(:update_resource, [kind, id, params])

  @impl true
  def zero(axis), do: error(:zero, [axis])

  @impl true
  def perform_lua(expression, extra_vars, comment),
    do: error(:perform_lua, [expression, extra_vars, comment])

  @impl true
  def fbos_config(), do: error(:fbos_config, [])

  defp error(fun, _args) do
    msg = """
    CeleryScript syscall stubbed: #{fun}
    """

    {:error, msg}
  end
end
