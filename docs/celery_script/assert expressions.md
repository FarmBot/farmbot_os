# CeleryScript Assert expressions.

The CeleryScript `if` block takes a possible left hand side value of
`expression` which allows an arbitrary string to be evaluated. This 
expression is evaluated against a lua 5.2 interpreter. 

## Lua API
The following functions are available for usage along with [Lua's 
standard library](https://www.lua.org/manual/5.2/). 

```lua
-- Comments are ignored by the interpreter

-- get_position()
--    Returns a table containing the current position data

position = get_position();
if position.x <= 20.55 then
  return true;
else
  print("current position: (", position.x, ",", position.y, "," position.z, ")");
  return false;
end

return get_position("y") <= 20;

-- get_pins()
--    Returns a table containing current pin data

pins = get_pins();
if pins[9] == 1.0 then
  return true;
end

return get_pin(10) == 0;

-- send_message(type, message, channels)
--    Sends a message to farmbot's logger

send_message("info", "hello, world", ["toast"]);

-- calibrate(axis)
--    calibrate an axis

calibrate("x");
calibrate("y");
calibrate("z");

-- emergency_lock()
-- emergency_unlock()
--    lock and unlock farmbot's firmware.
send_message("error", "locking the firmware!");
emergancy_lock();
emergency_unlock();

-- find_home(axis)
--    Find home on an axis.

find_home("x");
find_home("y");
find_home("z");

-- home(axis)
--    Go to home on an axis.

home("x");
home("y");
home("z");

-- coordinate(x, y, z)
--    create a vec3
move_to = coordinate(1.0, 0, 0);

-- move_absolute(x, y, z)
--    Move in a line to a position
move_absolute(1.0, 0, 0);
move_absolute(coordinate(1.0, 20, 30));

-- check_position(vec3, tolerance)
--    Check a position against Farmbot's current
--    position within a error threshold

move_absolute(1.0, 0, 0);
return check_position({x = 1.0, y = 0; z = 0}, 0.50);

move_absolute(20, 100, 100);
return check_position(coordinate(20, 100, 100), 1);

-- read_status(arg0)
--    Get a field on farmbot's current state

status = read_status();
return status.informational_settings.wifi_level >= 5;

return read_status("location_data", "raw_encoders") >= 1900;

-- version()
--    return Farmbot's current version
return version() == "8.1.2";

-- get_device(field)
--    return the device settings

return get_device().timezone == "America/los_angeles";

return get_device("name") == "Test Farmbot";

-- update_device(table)
--    update device settings

update_device({name = "Test Farmbot"});

-- get_fbos_config(field)
--    return the current fbos_config

return get_fbos_config("auto_sync");
return get_fbos_config().os_auto_update;

-- update_fbos_config(table)
--    update the current fbos_config

update_fbos_config({auto_sync = true, os_auto_update = false});

-- get_firmware_config(field)
--    return current firmware_config data

return get_firmware_config().encoder_enabled_x == 1.0;

return get_firmware_config("encoder_enabled_z");

-- update_firmware_config(table)
--    update current firmware_config data

update_firmware_config({encoder_enabled_z = 1.0});
```

## Expression contract
Expressions are expected to be evaluated in a certain way. The evaluation will fail
if this contract is not met. An expression should return one of the following values:
* `true`
* `false`
* `("error", "string reason signaling an error happened")`

### Examples

Check if the x position is within a range of 5 and 10

```lua
position = get_position();
return position.x >= 5 and position.x <= 10;
```

Check is a pin is a toggled, with error checking

```lua
-- All farmbot functions will return a tuple containing an error
-- if something bad happens

position, positionErr = get_position();
pins, pinErr = get_pins();
if positionErr or pinErr then
  return "error", positionErr or pinErr;
else
  return pins[9] == 1.0
end
```

```lua
time = current_hour() + ":" + current_minute() + ":" + current_second();
return time == "10:15:20"
```