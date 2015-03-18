require 'spec_helper'
require './lib/status.rb'
require './lib/handlers/messagehandler.rb'
require './spec/fixtures/stub_messenger.rb'
require './lib/handlers/messagehandler_emergencystop.rb'

describe MessageHandlerEmergencyStop do
  let(:message_handler) { MessageHandler.new(StubMessenger.new) }

  before do
    $db_write_sync = Mutex.new
    DbAccess.current = DbAccess.new('development')
    DbAccess.current = DbAccess.current
    DbAccess.current.disable_log_to_screen()

    Status.current = Status.new

    messaging = StubMessenger.new
    messaging.reset

    @handler = MessageHandlerEmergencyStop.new(messaging)
    @main_handler = MessageHandler.new(messaging)
  end

  ## messaging

  it "white list" do
    list = @handler.whitelist
    expect(list.count).to eq(2)
  end

  it "message handler emergency stop" do
    message = MessageHandlerMessage.new({}, message_handler)
    message.handled = false
    message.handler = @main_handler

    @handler.emergency_stop(message)

    expect(Status.current.emergency_stop).to eq(true)
    expect(@handler.messaging.message[:message_type]).to eq('confirmation')
  end

  it "message handler emergency stop reset" do
    message = MessageHandlerMessage.new({}, message_handler)
    message.handled = false
    message.handler = @main_handler

    @handler.emergency_stop_reset(message)

    expect(Status.current.emergency_stop).to eq(false)
    expect(@handler.messaging.message[:message_type]).to eq('confirmation')
  end


end
