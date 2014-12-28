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
