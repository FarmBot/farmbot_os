# CeleryScript IF `expression` field.

The CeleryScript `if` block takes a possible left hand side value of
`expression` which allows an arbitrary string to be evaluated. This 
expression is evaluated against a lua 5.2 interpreter. 

## Lua API
The following functions are available for usage along with [Lua's 
standard library](https://www.lua.org/manual/5.2/). 

```lua
-- Comments are ignored by the interpreter

-- help(function_name)
--    Returns docs for a function

print(help("send_message"));
print(help("get_position"));

-- get_position()
--    Returns a table containing the current position data

position = get_position();
if position.x <= 20.55 then
  return true;
else
  print("current position: (", position.x, ",", position.y, "," position.z, ")");
  return false;
end

-- get_pins()
--    Returns a table containing current pin data

pins = get_pins();
if pins[9] == 1.0 then
  return true;
end

-- send_message(type, message, channels)
--    Sends a message to farmbot's logger

send_message("info", "hello, world", ["toast"])
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