require 'spec_helper'
require './lib/status.rb'
require './lib/messaging/messagehandler.rb'
require './lib/messaging/messaging_test.rb'
require './lib/messaging/messagehandler_emergencystop.rb'

describe MessageHandlerEmergencyStop do

  before do
    $db_write_sync = Mutex.new
    DbAccess.current = DbAccess.new('development')
    DbAccess.current = DbAccess.current
    DbAccess.current.disable_log_to_screen()

    $status = Status.new

    @messaging = MessagingTest.new
    @messaging.reset

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
    expect(@messaging.message[:message_type]).to eq('confirmation')
  end

  it "message handler emergency stop reset" do
    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler

    @handler.emergency_stop_reset(message)

    expect($status.emergency_stop).to eq(false)
    expect(@messaging.message[:message_type]).to eq('confirmation')
  end


end
