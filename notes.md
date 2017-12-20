# Problem

 * Nodes didn't have a way of knowing their `🔗parent`
 * Solution: flatten the tree (see example below)
 * New problem: we need to know our "current location" while executing the sequence.
 * bigger problem: we need to know what our _next_ location will be (control flow).

I've determined three strategies: `special`, `standard` and `none`

# "Special" Rules

So far, only the `_if` node has special control flow rules. A `for_each` node might cause this, also.

# Standard Control Flow

Rules:

1. Does it have a `🔗next` attr?
2. If `(🔗next && (🔗next !== 0)) ? jump_to_🔗next : jump_to_🔗parent`
Is it `not 0`? If so, jump there next.
`home` `find_home` `zero` `emergency_lock` `emergency_unlock` `read_status` `sync` `check_updates` `power_off` `reboot` `toggle_pin` `rpc_request` `calibrate` `register_gpio` `unregister_gpio` `config_update` `factory_reset` `execute_script` `set_user_env` `take_photo` `install_farmware` `remove_farmware` `parameter_declaration` `install_first_party_farmware` `set_servo_angle` `wait` `send_message` `execute` `sequence` `move_absolute` `move_relative` `write_pin` `read_pin`

# No Control flow

`nothing` `tool` `coordinate` `channel` `explanation` `rpc_ok` `rpc_error` `pair` `point` `update_farmware` `scope_declaration` `identifier` `variable_declaration`

# Example
```
%{
  0 => %{
    __KIND__: "NULL"
  },
  1 => %{
    :__KIND__ => "sequence",
    "is_outdated" => false,
    "label" => "Move Relative Test",
    "version" => 6,
    "🔗body" => 2,
    "🔗locals" => 6,
    "🔗parent" => 0
  },
  2 => %{
    :__KIND__ => "move_relative",
    "speed" => 100,
    "x" => 0,
    "y" => 100,
    "z" => 0,
    "🔗next" => 3,
    "🔗parent" => 1
  },
  3 => %{
    :__KIND__ => "move_relative",
    "speed" => 100,
    "x" => 0,
    "y" => -100,
    "z" => 0,
    "🔗next" => 4,
    "🔗parent" => 2
  },
  4 => %{
    :__KIND__ => "send_message",
    "message" => "Move Relative test complete",
    "message_type" => "success",
    "🔗body" => 5,
    "🔗next" => 0,
    "🔗parent" => 3
  },
  5 => %{
    :__KIND__ => "channel",
    "channel_name" => "toast",
    "🔗next" => 0,
    "🔗parent" => 4
  },
  6 => %{
    :__KIND__ => "scope_declaration",
    "🔗parent" => 1
  }
}
```
