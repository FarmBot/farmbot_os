defmodule FarmbotOS.Celery.SysCallGlue.StubsTest do
  use ExUnit.Case
  alias FarmbotOS.Celery.SysCallGlue.Stubs

  test "various stubs" do
    # This test is to:
    #  * Catch early problems caused by a downstream stub
    #  * Keep coverage consistent
    #  * Detect unused stubs over time.
    args = "args"
    axis = "axis"
    channels = "channels"
    comment = "comment"
    env_name = "env_name"
    env_value = "env_value"
    expr = "expr"
    expression = "expression"
    force? = "force?"
    id = "id"
    kind = "kind"
    message = "message"
    millis = "millis"
    mode = "mode"
    named_pin_type = "named_pin_type"
    package = "package"
    params = "params"
    pin = "pin"
    pin_mode = "pin_mode"
    pin_num = "pin_num"
    pin_value = "pin_value"
    point_type = "point_type"
    resource_id = "resource_id"
    speed = "speed"
    sx = "sx"
    sy = "sy"
    sz = "sz"
    type = "type"
    value = "value"
    x = "x"
    y = "y"
    z = "z"

    Stubs.calibrate(axis)
    Stubs.check_update()
    Stubs.coordinate(x, y, z)
    Stubs.emergency_lock()
    Stubs.emergency_unlock()
    Stubs.perform_lua(expression, [], comment)
    Stubs.execute_script(package, args)
    Stubs.factory_reset(package)
    Stubs.find_home(axis)
    Stubs.find_points_via_group(id)
    Stubs.firmware_reboot()
    Stubs.flash_firmware(package)
    Stubs.get_cached_x()
    Stubs.get_cached_y()
    Stubs.get_cached_z()
    Stubs.get_current_x()
    Stubs.get_current_y()
    Stubs.get_current_z()
    Stubs.get_sequence(resource_id)
    Stubs.get_toolslot_for_tool(resource_id)
    Stubs.home(axis, speed)
    Stubs.log(message, force?)
    Stubs.move_absolute(x, y, z, speed)
    Stubs.move_absolute(x, y, z, sx, sy, sz)
    Stubs.named_pin(named_pin_type, resource_id)
    Stubs.nothing()
    Stubs.point(point_type, resource_id)
    Stubs.power_off()
    Stubs.perform_lua(expr, [], nil)
    Stubs.read_cached_pin(pin_num)
    Stubs.read_pin(pin_num, pin_mode)
    Stubs.read_status()
    Stubs.reboot()
    Stubs.send_message(type, message, channels)
    Stubs.sequence_complete_log(message)
    Stubs.sequence_init_log(message)
    Stubs.set_pin_io_mode(pin, mode)
    Stubs.set_servo_angle(pin, value)
    Stubs.set_user_env(env_name, env_value)
    Stubs.sync()
    Stubs.toggle_pin(pin_num)
    Stubs.update_resource(kind, id, params)
    Stubs.wait(millis)
    Stubs.write_pin(pin_num, pin_mode, pin_value)
    Stubs.zero(axis)
  end
end
