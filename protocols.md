Protocol
========

This document is an inventary for the messages used between the bakend and the farmbot

Basics
------

The farmbot hardware communicates with the backend trough the skynet protocol, a machine instant messaging protocol. All information is packaged as JSON. A typical message in skynet looks like this:

```
{
  "devices"=>"44128811-8c59-11e3-b99a-11476114e05f", 
  "message"=>
  {
    "message_type"=>"confirmation", 
    "time_stamp"=>"1403894016.000322"
  }, 
  "fromUuid"=>"68591ebf-d354-4a3a-8b83-0453bf4e8b23"
}
````

Everything in the message variable is custom. Skynet itself will always use create the device, message and fromUuid variable.

For farmbot, two elements are always present in the message:

|variable|example value|description|
|--------|-------------|-----------|
|message\_type | single\_command|the type of message|
|time\_stamp|1403805036.4898174|a string value to make the message unique|

The message type is a string that defines what the message does. Current available message types are:

|send by backend        |response by farmbot      |
|-----------------------|-------------------------|
|single\_command        |confirmation             |
|read\_parameters       |read\_parameters_response|
|read\_status           |read\_status\_response   |
|read\_logs             |read\_logs\_response     |
|write\_parameters      |confirmation             |
|crop\_schedule\_update |confirmation             |

Confirmation
------------

Some messages get a short response as a confirmation from the farmbot that the message is read and processed. The farmbot puts into 'confirm_id' the 'time_stamp' of the message that is processed.

```
{
  "message_type"=>"confirmation", 
  "time_stamp"=>"1403894016.000322", 
  "confirm_id"=>"1403894021.7605221"
}
```

Basic movement
==============

To move the farmbot manually, a message is send with type 'single command'. The farmbot will put the command into the schedule for immediate execution. The message looks like:

```
{
  :message_type=>"single_command", 
  :time_stamp=>"1403805036.4898174", 
  :command=>
  {
    :action=>"MOVE RELATIVE", 
    :x=>0, 
    :y=>10, 
    :z=>0, 
    :speed=>"manouvering", 
    :amount=>0, 
    :delay=>0
  }
}
```

variable|type|desciption
--------|----|----------
action  |string |the action/movement to do
x       |decimal|in absolute mode, the new place to move to. in relative mode, the amount to move, in millimeter
y       |decimal|same as x
z       |decimal|same as x
speed   |string |speed for movements, as text. for example 'traveling', 'manouvering'
amount  |decimal|amount of mililiter of water to dose. always add parameter with default value
delay   |decimal|amount in seconds to delay the execution of a command

actions and parameters used:

action       |x      |y      |z      |speed|amount|delay
-------------|-------|-------|-------|-----|------|-----
MOVE RELATIVE|X      |X      |X      |X    |      |X    
MOVE ABSOLUTE|X      |X      |X      |X    |      |X
DOSE WATER   |       |       |       |     |X     |X
HOME X       |       |       |       |X    |      |X
HOME Y       |       |       |       |X    |      |X
HOME Z       |       |       |       |X    |      |X

Device status
=============

Read status
-----------

```
{
  :message_type => "read_status", 
  :time_stamp   => "1403818238.3181107"
}

{
  "message_type"                   => "read_status_return", 
  "time_stamp"                     => "1403818234.1559582", 
  "confirm_id"                     => "1403818238.3181107", 
  "status"                         => "no command found, waiting", 
  "status_time_local"              => "2014/06/26 20:30:34 -0100", 
  "status_nr_msg_received"         => 7, 
  "status_movement"                => "idle", 
  "status_last_command_executed"   => "2014/06/26 20:05:08 -0100", 
  "status_next_command_scheduled"  => nil, 
  "status_nr_of_commands_executed" => 1
}
```

Read logs
---------

Sending the read log command to the farmbot and it will reply with a list of all recent logs

```
{
  :message_type => "read_logs", 
  :time_stamp   => "1403805653.5407457"
}

{
  "devices"=>"44128811-8c59-11e3-b99a-11476114e05f", 
  "message"=>
  {
    "message_type"=>"read_parameters_response", 
    "time_stamp"=>"1403820163.8032863", 
    "confirm_id"=>"1403820168.4028015", 
    "logs"=>
    [
      {"text"=>"Controller running", "module"=>1, "time"=>"2014/06/26 21:01:11 -0100"}, 
      {"text"=>"sender 44128811-8c59-11e3-b99a-11476114e05f", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, 
      {"text"=>"message_type = single_command", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, 
      {"text"=>"handle single command", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, 
      {"text"=>"sender = 44128811-8c59-11e3-b99a-11476114e05f", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, 
      {"text"=>"[MOVE RELATIVE] x: 0, y: 10, z: 0, speed: 0, amount: 0 delay: 0", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, 
      {"text"=>"[SIM] move relative xyz=0.0 10.0 0.0 amt=0.0 spd=0", "module"=>1, "time"=>"2014/06/26 21:01:23 -0100"}, 
      {"text"=>"sending comfirmation", "module"=>2, "time"=>"2014/06/26 21:01:23 -0100"}, 
      {"text"=>"done", "module"=>2, "time"=>"2014/06/26 21:01:24 -0100"}
    ]
  }
}
```

Parameter management
====================

The list of parameters in the system when using a RAMPS system:

parameter                |type|unit of measurement
-------------------------|----|-------------------
ramps_move_home_timeout_x|1   |millimeter
ramps_move_home_timeout_y|1   |millimeter
ramps_move_home_timeout_z|1   |millimeter
ramps_invert_axis_x      |4   |0/1
ramps_invert_axis_y      |4   |0/1
ramps_invert_axis_z      |4   |0/1
ramps_steps_per_unit_x   |1   |millimeter
ramps_steps_per_unit_y   |1   |millimeter
ramps_steps_per_unit_z   |1   |millimeter
ramps_pos_max_x          |1   |millimeter
ramps_pos_max_y          |1   |millimeter
ramps_pos_max_z          |1   |millimeter
ramps_pos_min_x          |1   |millimeter
ramps_pos_min_y          |1   |millimeter
ramps_pos_min_z          |1   |millimeter
ramps_reverse_home_x     |4   |0/1
ramps_reverse_home_y     |4   |0/1
ramps_reverse_home_z     |4   |0/1

The type id number used for storing in sqlite

id   |type
-----|---------
1    |integer
2    |float
3    |string
4    |boolean

Reading parameters
------------------

If you send a message for reading the parameters, farmbot will reply with a list of all parameters present in the system. The list of parameters are created at the first boot of the system.

```
{
  :message_type=>"read_parameters", 
  :time_stamp=>"1403816116.954407"
}

{
  "message_type"=>"read_parameters_response", 
  "time_stamp"=>"1403816112.8748097", 
  "confirm_id"=>"1403816116.954407", 
  "parameters"=>
  [
    {"name"=>"ramps_move_home_timeout_x", "type"=>1, "value"=>31}, 
    {"name"=>"ramps_move_home_timeout_y", "type"=>1, "value"=>32}, 
    {"name"=>"ramps_move_home_timeout_z", "type"=>1, "value"=>33}
  ]
}
```


Writing parameters
------------------

This message is used to send a list of the values that need to be changed to the farmbot. It will reply with a simple confirmation

```
{
  :message_type=>"write_parameters", 
  :time_stamp=>"1403812040.7974331", 
  :parameters=>
  [
    {:name=>"ramps_move_home_timeout_x", :type=>1, :value=>30}, 
    {:name=>"ramps_move_home_timeout_y", :type=>1, :value=>35}, 
    {:name=>"ramps_move_home_timeout_z", :type=>1, :value=>40}
  ]
}
```
