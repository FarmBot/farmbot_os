require 'spec_helper'
require './lib/messaging/messagehandler_emergencystop.rb'
require './lib/status.rb'
require './lib/messaging/messaging.rb'
require './lib/messaging/messaging_test.rb'

describe MessageHandlerEmergencyStop do

  before do
    #$db_write_sync = Mutex.new
    #$dbaccess = DbAccess.new('development')
    #@msg = MessageHandler.new

    $db_write_sync = Mutex.new
    $bot_dbaccess = DbAccess.new('development')
    $dbaccess = $bot_dbaccess
    $dbaccess.disable_log_to_screen()

    $status = Status.new

    Messaging.current = MessagingTest.new
    Messaging.current.reset

    @handler = MessageHandlerEmergencyStop.new
    @main_handler = MessageHandler.new
  end

  ## messaging

  it "white list" do
    list = @handler.whitelist
    expect(list.count).to eq(2)
  end

  it "message handler emergency stop" do
    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler

    @handler.emergency_stop(message)

    expect($status.emergency_stop).to eq(true)
    expect(Messaging.current.message[:message_type]).to eq('confirmation')
  end

  it "message handler emergency stop reset" do
    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler

    @handler.emergency_stop_reset(message)

    expect($status.emergency_stop).to eq(false)
    expect(Messaging.current.message[:message_type]).to eq('confirmation')
  end


end
