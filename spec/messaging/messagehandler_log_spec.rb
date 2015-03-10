require 'spec_helper'
require './lib/status.rb'
require './lib/messaging/messaging.rb'
require './lib/messaging/messaging_test.rb'
require './lib/messaging/messagehandler_logs.rb'

describe MessageHandlerLog do

  before do
    $db_write_sync = Mutex.new
    $bot_dbaccess = DbAccess.new('development')
    $dbaccess = $bot_dbaccess
    $dbaccess.disable_log_to_screen()

    $status = Status.new

    Messaging.current = MessagingTest.new
    Messaging.current.reset

    @handler = MessageHandlerLog.new
    @main_handler = MessageHandler.new
  end

  ## logs

  it "white list" do
    list = @handler.whitelist
    expect(list.count).to eq(1)
  end

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

    return_list = Messaging.current.message

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
    expect(Messaging.current.message[:message_type]).to eq('read_logs_response')
  end

end
