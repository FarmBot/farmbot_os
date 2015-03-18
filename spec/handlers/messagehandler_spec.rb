require 'spec_helper'
require './spec/fixtures/stub_messenger.rb'
require './lib/handlers/messagehandler.rb'
require './lib/handlers/messagehandler_base.rb'
require './lib/handlers/messagehandler_message.rb'


describe MessageHandler do


  before do
    $db_write_sync = Mutex.new
    DbAccess.current = DbAccess.new('development')
    $dbaccess = DbAccess.current
    $dbaccess.disable_log_to_screen()

    #Status.current = Status.new

    messaging = StubMessenger.new
    messaging.reset

    @handler = MessageHandler.new(messaging)
  end

  it "handle message with test message" do


    fromUuid     = rand(9999999).to_s
    message_type = 'test'
    time_stamp   = Time.now.to_f.to_s

    message =
      {
        'fromUuid' => fromUuid,
        'payload' =>
          {
            'message_type' => message_type,
            'time_stamp'   => time_stamp
          }
      }

    @handler.handle_message(message)

    expect(@handler.messaging.message[:message_type]).to eq('error')
  end

  it "handle message - test error handling" do

    fromUuid     = ''
    message_type = 'test'
    time_stamp   = Time.now.to_f.to_s

    message =
      {
        'fromUuid' => fromUuid,
        'payload' => nil
      }

    @handler.handle_message(message)

    expect(@handler.messaging.message[:message_type]).to eq('error')
    expect(@handler.messaging.device).to eq(fromUuid)
  end

  it "return error" do
    ret = @handler.error
    expect(ret).to eq({:error => ''})
  end

  it "send confirmation" do
    destination     = rand(9999999).to_s
    time_stamp      = nil

    @handler.send_confirmation(destination, time_stamp)

    expect(@handler.messaging.message[:message_type]).to eq('confirmation')
    expect(@handler.messaging.device).to eq(destination)

  end

  it "send error" do
    destination     = rand(9999999).to_s
    error           = rand(9999999).to_s
    time_stamp      = nil

    @handler.send_error(destination, time_stamp, error)

    expect(@handler.messaging.message[:message_type]).to eq('error')
    expect(@handler.messaging.device).to eq(destination)

  end
end
