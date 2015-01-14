require 'spec_helper'
require './lib/status.rb'
require './lib/hardware/gcode/ramps_arduino.rb'
require './lib/database/dbaccess.rb'

describe HardwareInterfaceArduino do

  before do
    $db_write_sync = Mutex.new
    $bot_dbaccess = DbAccess.new('development')
    $dbaccess = $bot_dbaccess
    $dbaccess.disable_log_to_screen()

    $status = Status.new

    @ramps = HardwareInterfaceArduino.new(true)

  end

  it "read status" do
    @ramps.connect_board
    expect(1).to eq(1)
  end

  it "execute_command"  do

    command = "TEST"

    @ramps.test_serial_read = "R01\nR02\n"
    @ramps.execute_command(command, false, false)

#:test_string_read, :test_string_write

    expect(@ramps.test_serial_write).to eq("#{command}\n")

  end

  it "create write status" do

    text     = rand(9999999).to_s 
    log      = rand(9999999).to_s
    onscreen = true
    
    write_status = @ramps.create_write_status(text, log, onscreen)

    expect(write_status.text     ).to eq(text     )
    expect(write_status.log      ).to eq(log      )
    expect(write_status.onscreen ).to eq(onscreen )

  end

  it "handle execution exception" do
    e = Exception.new
    @ramps.handle_execution_exception(e)
    expect(1).to eq(1)
  end

  it "log result of execution" do

    text     = rand(9999999).to_s 
    log      = rand(9999999).to_s
    onscreen = true
    
    write_status = @ramps.create_write_status(text, log, onscreen)

    @ramps.log_result_of_execution(write_status)

    expect(1).to eq(1)
  end

  it "process feedback" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false
    
    @ramps.test_serial_read = "R02\n"

    write_status = @ramps.create_write_status(text, log, onscreen)

    @ramps.process_feedback(write_status)
    @ramps.process_feedback(write_status)
    @ramps.process_feedback(write_status)
    @ramps.process_feedback(write_status)
    @ramps.process_feedback(write_status)
    
    expect(write_status.done).to eq(1)

  end

  it "and and process characters" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false
    
    write_status = @ramps.create_write_status(text, log, onscreen)

    @ramps.add_and_process_characters(write_status, 'R')
    @ramps.add_and_process_characters(write_status, '0')
    @ramps.add_and_process_characters(write_status, '2')
    @ramps.add_and_process_characters(write_status, "\n")

    expect(write_status.done).to eq(1)

  end

  it "process codes and parameters R01" do



  end

end


=begin
require 'spec_helper'
require './lib/status.rb'
require './lib/messaging/messaging.rb'
require './lib/messaging/messaging_test.rb'
require './lib/messaging/messagehandler_logs.rb'
require './lib/hardware/gcode/ramps_arduino.rb'

describe HardwareInterfaceArduino do

  before do
    $db_write_sync = Mutex.new
    $bot_dbaccess = DbAccess.new('development')
    $dbaccess = $bot_dbaccess
    $dbaccess.disable_log_to_screen()

    $status = Status.new

    $messaging = MessagingTest.new
    $messaging.reset

    @handler = MessageHandlerLog.new
    @main_handler = MessageHandler.new
  end

  ## logs
  
  it "read logs" do

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

end
=end
