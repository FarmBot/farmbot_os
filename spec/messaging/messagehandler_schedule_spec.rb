require 'spec_helper'
require './lib/status.rb'
require './lib/messaging/messaging.rb'
require './lib/messaging/messaging_test.rb'

#require './lib/messagehandler_schedule'
#require './lib/messagehandler_schedule_cmd_line'
#require './lib/messaging/messagehandler_logs.rb'

describe MessageHandlerSchedule do

  before do
    $db_write_sync = Mutex.new
    $bot_dbaccess = DbAccess.new('development')
    $dbaccess = $bot_dbaccess
    $dbaccess.disable_log_to_screen()

    $status = Status.new

    $messaging = MessagingTest.new
    $messaging.reset

    @handler = MessageHandlerSchedule.new
    @main_handler = MessageHandler.new
  end

  ## commands / scheduling
  
#def single_command(message)
#def save_single_command(command, delay)
#def save_command_line(command)
#def crop_schedule_update(message)
#def save_command_with_lines(command)

=begin
  it "save command line" do

    # create new command data

    sched_time    = Time.now
    crop_id       = rand(9999999).to_i
    action        = rand(9999999).to_s
    x             = rand(9999999).to_i
    y             = rand(9999999).to_i
    z             = rand(9999999).to_i
    speed         = rand(9999999).to_s
    amount        = rand(9999999).to_i
    pin_nr        = rand(9999999).to_i
    pin_value1    = rand(9999999).to_i
    pin_value2    = rand(9999999).to_i
    pin_mode      = rand(9999999).to_i
    pin_time      = rand(9999999).to_i
    ext_info      = rand(9999999).to_s
    delay         = rand(     99).to_i

    # save the new command in the database

    command = 
      {
        'action'        => action        ,
        'delay'         => delay         ,
        'x'             => x             ,
        'y'             => y             ,
        'z'             => z             ,
        'speed'         => speed         ,
        'amount'        => amount        ,
        'pin'           => pin_nr        ,
        'value1'        => pin_value1    ,
        'value2'        => pin_value2    ,
        'mode'          => pin_mode      ,
        'time'          => pin_time      ,
        'info'          => ext_info
      }

    command_obj = MessageHandlerScheduleCmdLine.new
    command_obj.split_command_line( command )

    $dbaccess.create_new_command(sched_time,crop_id)
    @handler.save_command_line(command_obj)
    $dbaccess.save_new_command

    # get the data back from the database

    cmd = Command.where("scheduled_time = ?",sched_time).first
    line = CommandLine.where("command_id = ?",cmd.id).first
#    line = CommandLine.where("command_id = ? and external_info = ?",cmd.id, ext_info).first

    # do the checks

    expect(cmd.crop_id       ).to eq(crop_id      )
    expect(line.action       ).to eq(action       )
    expect(line.external_info).to eq(ext_info     )
    expect(line.coord_x      ).to eq(x            )
    expect(line.coord_y      ).to eq(y            )
    expect(line.coord_z      ).to eq(z            )
    expect(line.speed        ).to eq(speed        )
    expect(line.amount       ).to eq(amount       )
    expect(line.pin_nr       ).to eq(pin_nr       )
    expect(line.pin_value_1  ).to eq(pin_value1   )
    expect(line.pin_value_2  ).to eq(pin_value2   )
    expect(line.pin_mode     ).to eq(pin_mode     )
    expect(line.pin_time     ).to eq(pin_time     )
    
  end

  it "save single command" do

    # create new command data

    sched_time    = Time.now
    crop_id       = rand(9999999).to_i
    action        = rand(9999999).to_s
    x             = rand(9999999).to_i
    y             = rand(9999999).to_i
    z             = rand(9999999).to_i
    speed         = rand(9999999).to_s
    amount        = rand(9999999).to_i
    pin_nr        = rand(9999999).to_i
    pin_value1    = rand(9999999).to_i
    pin_value2    = rand(9999999).to_i
    pin_mode      = rand(9999999).to_i
    pin_time      = rand(9999999).to_i
    ext_info      = rand(9999999).to_s
    delay         = rand(     99).to_i + 10 

    # save the new command in the database

    command = 
      {
        'action'        => action        ,
        'delay'         => delay         ,
        'x'             => x             ,
        'y'             => y             ,
        'z'             => z             ,
        'speed'         => speed         ,
        'amount'        => amount        ,
        'pin'           => pin_nr        ,
        'value1'        => pin_value1    ,
        'value2'        => pin_value2    ,
        'mode'          => pin_mode      ,
        'time'          => pin_time      ,
        'info'          => ext_info
      }

    command_obj = MessageHandlerScheduleCmdLine.new
    command_obj.split_command_line(command)

    @handler.save_single_command(command_obj,  delay)

    # get the data back from the database

    cmd = Command.where("scheduled_time >= ?",sched_time + 10).first
    line = CommandLine.where("command_id = ?",cmd.id).first

    # do the checks

    expect(line.action       ).to eq(action       )
    expect(line.external_info).to eq(ext_info     )
    expect(line.coord_x      ).to eq(x            )
    expect(line.coord_y      ).to eq(y            )
    expect(line.coord_z      ).to eq(z            )
    expect(line.speed        ).to eq(speed        )
    expect(line.amount       ).to eq(amount       )
    expect(line.pin_nr       ).to eq(pin_nr       )
    expect(line.pin_value_1  ).to eq(pin_value1   )
    expect(line.pin_value_2  ).to eq(pin_value2   )
    expect(line.pin_mode     ).to eq(pin_mode     )
    expect(line.pin_time     ).to eq(pin_time     )
    
  end

  it "handle single command" do

    # create new command data

    sched_time    = Time.now
    crop_id       = rand(9999999).to_i
    action        = rand(9999999).to_s
    x             = rand(9999999).to_i
    y             = rand(9999999).to_i
    z             = rand(9999999).to_i
    speed         = rand(9999999).to_s
    amount        = rand(9999999).to_i
    pin_nr        = rand(9999999).to_i
    pin_value1    = rand(9999999).to_i
    pin_value2    = rand(9999999).to_i
    pin_mode      = rand(9999999).to_i
    pin_time      = rand(9999999).to_i
    ext_info      = rand(9999999).to_s
    delay         = rand(     99).to_i

    # create a message

    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler
    message.payload = 
      {
        'command'  => 
        {
          'delay'  => delay      ,
          'action' => action     ,
          'x'      => x          ,
          'y'      => y          ,
          'z'      => z          ,
          'speed'  => speed      ,
          'amount' => amount     ,
          'pin'    => pin_nr     ,
          'value1' => pin_value1 ,
          'value2' => pin_value2 ,
          'mode'   => pin_mode   ,
          'time'   => pin_time   ,
          'info'   => ext_info
        }
      }

    # execute the message

    @handler.single_command(message)

    # get the data back from the database

    cmd = Command.where("scheduled_time >= ?",sched_time).first
    line = CommandLine.where("command_id = ?",cmd.id).first

    # do the checks

    expect(line.action       ).to eq(action       )
    expect(line.external_info).to eq(ext_info     )
    expect(line.coord_x      ).to eq(x            )
    expect(line.coord_y      ).to eq(y            )
    expect(line.coord_z      ).to eq(z            )
    expect(line.speed        ).to eq(speed        )
    expect(line.amount       ).to eq(amount       )
    expect(line.pin_nr       ).to eq(pin_nr       )
    expect(line.pin_value_1  ).to eq(pin_value1   )
    expect(line.pin_value_2  ).to eq(pin_value2   )
    expect(line.pin_mode     ).to eq(pin_mode     )
    expect(line.pin_time     ).to eq(pin_time     )
    
  end

=end

# save_command_with_lines

  it "save command with lines" do

    # create new command data

    sched_time      = Time.now
    crop_id         = rand(9999999).to_i

    action_A        = rand(9999999).to_s
    x_A             = rand(9999999).to_i
    y_A             = rand(9999999).to_i
    z_A             = rand(9999999).to_i
    speed_A         = rand(9999999).to_s
    amount_A        = rand(9999999).to_i
    pin_nr_A        = rand(9999999).to_i
    pin_value1_A    = rand(9999999).to_i
    pin_value2_A    = rand(9999999).to_i
    pin_mode_A      = rand(9999999).to_i
    pin_time_A      = rand(9999999).to_i
    ext_info_A      = rand(9999999).to_s
    delay_A         = rand(     99).to_i
    
    action_B        = rand(9999999).to_s
    x_B             = rand(9999999).to_i
    y_B             = rand(9999999).to_i
    z_B             = rand(9999999).to_i
    speed_B         = rand(9999999).to_s
    amount_B        = rand(9999999).to_i
    pin_nr_B        = rand(9999999).to_i
    pin_value1_B    = rand(9999999).to_i
    pin_value2_B    = rand(9999999).to_i
    pin_mode_B      = rand(9999999).to_i
    pin_time_B      = rand(9999999).to_i
    ext_info_B      = rand(9999999).to_s
    delay_B         = rand(     99).to_i

    # create a command

    command = 
      {
        'scheduled_time' => sched_time.utc.to_s,
        'crop_id'        => crop_id        ,
        'command_lines'  => 
        [
          {
            'delay'  => delay_A      ,
            'action' => action_A     ,
            'x'      => x_A          ,
            'y'      => y_A          ,
            'z'      => z_A          ,
            'speed'  => speed_A      ,
            'amount' => amount_A     ,
            'pin'    => pin_nr_A     ,
            'value1' => pin_value1_A ,
            'value2' => pin_value2_A ,
            'mode'   => pin_mode_A   ,
            'time'   => pin_time_A   ,
            'info'   => ext_info_A
          },
          {
            'delay'  => delay_B      ,
            'action' => action_B     ,
            'x'      => x_B          ,
            'y'      => y_B          ,
            'z'      => z_B          ,
            'speed'  => speed_B      ,
            'amount' => amount_B     ,
            'pin'    => pin_nr_B     ,
            'value1' => pin_value1_B ,
            'value2' => pin_value2_B ,
            'mode'   => pin_mode_B   ,
            'time'   => pin_time_B   ,
            'info'   => ext_info_B
          }
        ]
      }

    # execute the message

    @handler.save_command_with_lines(command)

    # get the data back from the database

    cmd = Command.where("crop_id = ?",crop_id).first
    line_A = CommandLine.where("command_id = ?",cmd.id).first
    line_B = CommandLine.where("command_id = ?",cmd.id).last

    nr_of_lines = CommandLine.where("command_id = ?",cmd.id).count


    # do the checks

    expect(nr_of_lines         ).to eq(2              )

    expect(line_A.action       ).to eq(action_A       )
    expect(line_A.external_info).to eq(ext_info_A     )
    expect(line_A.coord_x      ).to eq(x_A            )
    expect(line_A.coord_y      ).to eq(y_A            )
    expect(line_A.coord_z      ).to eq(z_A            )
    expect(line_A.speed        ).to eq(speed_A        )
    expect(line_A.amount       ).to eq(amount_A       )
    expect(line_A.pin_nr       ).to eq(pin_nr_A       )
    expect(line_A.pin_value_1  ).to eq(pin_value1_A   )
    expect(line_A.pin_value_2  ).to eq(pin_value2_A   )
    expect(line_A.pin_mode     ).to eq(pin_mode_A     )
    expect(line_A.pin_time     ).to eq(pin_time_A     )

    expect(line_B.action       ).to eq(action_B       )
    expect(line_B.external_info).to eq(ext_info_B     )
    expect(line_B.coord_x      ).to eq(x_B            )
    expect(line_B.coord_y      ).to eq(y_B            )
    expect(line_B.coord_z      ).to eq(z_B            )
    expect(line_B.speed        ).to eq(speed_B        )
    expect(line_B.amount       ).to eq(amount_B       )
    expect(line_B.pin_nr       ).to eq(pin_nr_B       )
    expect(line_B.pin_value_1  ).to eq(pin_value1_B   )
    expect(line_B.pin_value_2  ).to eq(pin_value2_B   )
    expect(line_B.pin_mode     ).to eq(pin_mode_B     )
    expect(line_B.pin_time     ).to eq(pin_time_B     )
    
  end

# ==> crop schedule update

=begin

  it "single command" do

    # write a few lines in the log
    log_text_1   = rand(9999999).to_s
    log_text_2   = rand(9999999).to_s
    log_module_1 = 99
    log_module_2 = 98

    $dbaccess.write_to_log( log_module_1, log_text_1 )
    $dbaccess.write_to_log( log_module_2, log_text_2 )

    # get the logs in a message

    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler

    @handler.read_logs(message)

    return_list = $messaging.message

    # check if the logged lines are present in the message

    found_in_list_1       = false
    found_in_list_2       = false


    return_list[:logs].each do |item|
      if item['text'] == log_text_1 and item['module'] == log_module_1
        found_in_list_1 = true
      end
      if item['text'] == log_text_2 and item['module'] == log_module_2
        found_in_list_2 = true
      end
    end

    # check expectations

    expect(found_in_list_1).to eq(true)
    expect(found_in_list_2).to eq(true)
    expect($messaging.message[:message_type]).to eq('read_logs_response')
  end

=end

end
