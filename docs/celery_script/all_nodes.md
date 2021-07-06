# All CeleryScript Nodes

This list is split into three categories.

## RPC Nodes

Nodes that control Farmbot's state, but don't don't command
a real world side effect. This includes:

* updating configuration data.
* syncing.
* starting/stopping a process of some sort.
* rebooting

### RPC Node Table

| Name | Args | Body |
|:-: | :--:|:--:|
| `check_updates`| `package`| ---|
| `config_update`| `package`| `pair`|
| `uninstall_farmware`| `package`| ---|
| `update_farmware`| `package`| ---|
| `rpc_request`| `label`| `command` or `rpc` nodes|
| `rpc_ok`| `label`| ---|
| `rpc_error`| `label`| `explanation`|
| `install farmware`| `url`| ---|
| `read_status`| --- | ---|
| `sync`| --- | ---|
| `power_off`| --- | ---|
| `reboot`| --- | ---|
| `factory_reset`| --- | ---|
| `set_usr_env`| --- | `pair`|
| `install_first_party_farmware`|---|---|
| `change_ownership`| --- | `pair`|
| `dump_info`| --- | ---|

## Command Nodes

Nodes that physically do something. This includes:

* moving the gantry.
* writing or reading a GPIO.

### Command Node Table

| Name | Args | Body |
|:-: | :--:|:--:|
| `_if`| `lhs`, `op`, `rhs`, `_then`, `_else`| `pair`|
| `write_pin`| `pin_number`, `pin_value`, `pin_mode`| ---|
| `read_pin`| `pin_number`, `pin_value`, `pin_mode`| ---|
| `move_absolute`| `location`, `speed`, `offset`| ---|
| `set_servo_angle`| `pin_number`, `pin_value`| ---|
| `send_message`| `message`, `message_type`| `channel`|
| `move_relative`| `speed`, `x`, `y`, `z`| ---|
| `sequence`| `version`, `locals`| `any command node`|
| `home`| `speed`, `axis`| ---|
| `find_home`| `speed`, `axis`| ---|
| `wait`| `milliseconds`| ---|
| `execute`| `sequence_id`| ---|
| `toggle_pin`| `pin_number`| ---|
| `execute_script`| `package`| `pair`|
| `zero`| `axis`| ---|
| `calibrate`| `axis`| ---|
| `emergency_lock`| ---| ---|
| `emergency_unlock`| ---| ---|
| `take_photo`| ---| ---|

## Data Nodes

Nodes that simply contain data. They are not to be executed. This includes:

* explanation
* location data

### Data Node Table

| Name | Args | Body |
|:-: | :--:|:--:|
| `point`| `pointer_type`, `pointer_id`| ---|
| `named_pin`| `pin_type`, `pin_id`| ---|
| `pair`| `label`, `value`| ---|
| `channel`| `channel_name`| ---|
| `coordinate`| `x`, `y`, `z`| ---|
| `tool`| `tool_id`| ---|
| `explanation`| `message`| ---|
| `identifier`| `label`| ---|
| `nothing`| ---| ---|
| `scope_declaration`| ---| `parameter_declaration` or `variable_declaration`|
