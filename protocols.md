Basic movement
==============

{:message_type=>"single_command", :time_stamp=>"1403805036.4898174", :command=>{:action=>"MOVE RELATIVE", :x=>0, :y=>10, :z=>0, :speed=>0, :amount=>0, 

:delay=>0}}

{:message_type=>"single_command", :time_stamp=>"1403805269.8237755", :command=>{:action=>"DOSE WATER", :x=>0, :y=>0, :z=>0, :speed=>0, :amount=>15, 

:delay=>0}}


{:message_type=>"single_command", :time_stamp=>"1403805627.547262", :command=>{:action=>"HOME X", :x=>0, :y=>0, :z=>0, :speed=>0, :amount=>0, :delay=>0}}



Device status
=============

{:message_type=>"read_logs", :time_stamp=>"1403805653.5407457"}

{:message_type=>"read_status", :time_stamp=>"1403818238.3181107"}
{"devices"=>"44128811-8c59-11e3-b99a-11476114e05f", "message"=>{"message_type"=>"read_status_return", "time_stamp"=>"1403818234.1559582", 
"confirm_id"=>"1403818238.3181107", "status"=>"no command found, waiting", "status_time_local"=>"2014/06/26 20:30:34 -0100", "status_nr_msg_received"=>7, 
"status_movement"=>"idle", "status_last_command_executed"=>"2014/06/26 20:05:08 -0100", "status_next_command_scheduled"=>nil, 
"status_nr_of_commands_executed"=>1}, "fromUuid"=>"68591ebf-d354-4a3a-8b83-0453bf4e8b23"}


{:message_type=>"read_logs", :time_stamp=>"1403820168.4028015"}
{"devices"=>"44128811-8c59-11e3-b99a-11476114e05f", "message"=>{"message_type"=>"read_parameters_response", "time_stamp"=>"1403820163.8032863", "confirm_id"=>"1403820168.4028015", "logs"=>[{"text"=>"Controller running", "module"=>1, "time"=>"2014/06/26 21:01:11 -0100"}, {"text"=>"{\"devices\"=>\"68591ebf-d354-4a3a-8b83-0453bf4e8b23\", \"payload\"=>{\"message_type\"=>\"single_command\", \"time_stamp\"=>\"1403820086.0109582\", \"command\"=>{\"action\"=>\"MOVE RELATIVE\", \"x\"=>0, \"y\"=>10, \"z\"=>0, \"speed\"=>0, \"amount\"=>0, \"delay\"=>0}}, \"fromUuid\"=>\"44128811-8c59-11e3-b99a-11476114e05f\"}", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, {"text"=>"sender 44128811-8c59-11e3-b99a-11476114e05f", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, {"text"=>"message_type = single_command", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, {"text"=>"handle single command", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, {"text"=>"sender = 44128811-8c59-11e3-b99a-11476114e05f", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, {"text"=>"[MOVE RELATIVE] x: 0, y: 10, z: 0, speed: 0, amount: 0 delay: 0", "module"=>2, "time"=>"2014/06/26 21:01:21 -0100"}, {"text"=>"[SIM] move relative xyz=0.0 10.0 0.0 amt=0.0 spd=0", "module"=>1, "time"=>"2014/06/26 21:01:23 -0100"}, {"text"=>"sending comfirmation", "module"=>2, "time"=>"2014/06/26 21:01:23 -0100"}, {"text"=>"done", "module"=>2, "time"=>"2014/06/26 21:01:24 -0100"}, {"text"=>"{\"devices\"=>\"68591ebf-d354-4a3a-8b83-0453bf4e8b23\", \"payload\"=>{\"message_type\"=>\"read_logs\", \"time_stamp\"=>\"1403820091.1966734\"}, \"fromUuid\"=>\"44128811-8c59-11e3-b99a-11476114e05f\"}", "module"=>2, "time"=>"2014/06/26 21:01:26 -0100"}, {"text"=>"sender 44128811-8c59-11e3-b99a-11476114e05f", "module"=>2, "time"=>"2014/06/26 21:01:26 -0100"}, {"text"=>"message_type = read_logs", "module"=>2, "time"=>"2014/06/26 21:01:26 -0100"}, {"text"=>"handle read logs", "module"=>2, "time"=>"2014/06/26 21:01:26 -0100"}, {"text"=>"sender     = 44128811-8c59-11e3-b99a-11476114e05f", "module"=>2, "time"=>"2014/06/26 21:01:26 -0100"}, {"text"=>"time_stamp = 1403820091.1966734", "module"=>2, "time"=>"2014/06/26 21:01:26 -0100"}, {"text"=>"{\"devices\"=>\"68591ebf-d354-4a3a-8b83-0453bf4e8b23\", \"payload\"=>{\"message_type\"=>\"read_logs\", \"time_stamp\"=>\"1403820168.4028015\"}, \"fromUuid\"=>\"44128811-8c59-11e3-b99a-11476114e05f\"}", "module"=>2, "time"=>"2014/06/26 21:02:43 -0100"}, {"text"=>"sender 44128811-8c59-11e3-b99a-11476114e05f", "module"=>2, "time"=>"2014/06/26 21:02:43 -0100"}, {"text"=>"message_type = read_logs", "module"=>2, "time"=>"2014/06/26 21:02:43 -0100"}, {"text"=>"handle read logs", "module"=>2, "time"=>"2014/06/26 21:02:43 -0100"}, {"text"=>"sender     = 44128811-8c59-11e3-b99a-11476114e05f", "module"=>2, "time"=>"2014/06/26 21:02:43 -0100"}, {"text"=>"time_stamp = 1403820168.4028015", "module"=>2, "time"=>"2014/06/26 21:02:43 -0100"}]}, "fromUuid"=>"68591ebf-d354-4a3a-8b83-0453bf4e8b23"}


Parameter management
====================



{:message_type=>"write_parameters", :time_stamp=>"1403812040.7974331", :parameters=>[{:name=>"ramps_move_home_timeout_x", :type=>1, :value=>31}, 

{:name=>"ramps_move_home_timeout_y", :type=>1, :value=>32}]}


{:message_type=>"read_parameters", :time_stamp=>"1403816116.954
407"}



{"devices"=>"44128811-8c59-11e3-b99a-11476114e05f", "message"=>{"message_type"=>"read_parameters_response", "time_stamp"=>"1403816112.8748097", 

"confirm_id"=>"1403816116.954407", "parameters"=>[{"name"=>"ramps_move_home_timeout_x", "type"=>1, "value"=>31}, {"name"=>"ramps_move_home_timeout_y", 

"type"=>1, "value"=>32}, {"name"=>"ramps_move_home_timeout_z", "type"=>1, "value"=>15}, {"name"=>"ramps_invert_axis_x", "type"=>4, "value"=>false}, 

{"name"=>"ramps_invert_axis_y", "type"=>4, "value"=>false}, {"name"=>"ramps_invert_axis_z", "type"=>4, "value"=>false}, {"name"=>"ramps_steps_per_unit_x", 

"type"=>1, "value"=>5}, {"name"=>"ramps_steps_per_unit_y", "type"=>1, "value"=>5}, {"name"=>"ramps_steps_per_unit_z", "type"=>1, "value"=>5}, 

{"name"=>"ramps_pos_max_x", "type"=>1, "value"=>200}, {"name"=>"ramps_pos_max_y", "type"=>1, "value"=>200}, {"name"=>"ramps_pos_max_z", "type"=>1, 

"value"=>200}, {"name"=>"ramps_pos_min_x", "type"=>1, "value"=>0}, {"name"=>"ramps_pos_min_y", "type"=>1, "value"=>0}, {"name"=>"ramps_pos_min_z", 

"type"=>1, "value"=>0}, {"name"=>"ramps_reverse_home_x", "type"=>4, "value"=>false}, {"name"=>"ramps_reverse_home_y", "type"=>4, "value"=>false}, 

{"name"=>"ramps_reverse_home_z", "type"=>4, "value"=>false}]}, "fromUuid"=>"68591ebf-d354-4a3a-8b83-0453bf4e8b23"}




