require 'spec_helper'
require './lib/messaging/messaging_test.rb'
require './lib/messaging/messagehandler.rb'
require './lib/messaging/messagehandler_base.rb'
require './lib/messaging/messagehandler_message.rb'


describe MessageHandler do


  before do
    $db_write_sync = Mutex.new
    DbAccess.current = DbAccess.new('development')
    $dbaccess = DbAccess.current
    $dbaccess.disable_log_to_screen()

    #$status = Status.new

    $messaging = MessagingTest.new
    $messaging.reset

$mesh_msg_print = 1

    @handler = MessageHandler.new
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

    expect($messaging.message[:message_type]).to eq('error')
  end

  it "handle message - test error handling" do

    fromUuid     = nil
    message_type = 'test'
    time_stamp   = Time.now.to_f.to_s

    message =
      {
        'fromUuid' => fromUuid,
        'payload' => nil
      }

    @handler.handle_message(message)

    expect($messaging.message[:message_type]).to eq('error')
    expect($messaging.device).to eq(fromUuid)
  end

  it "return error" do
    ret = @handler.error
    expect(ret).to eq({:error => ''})
  end

  it "send confirmation" do
    destination     = rand(9999999).to_s
    time_stamp      = nil

    @handler.send_confirmation(destination, time_stamp)

    expect($messaging.message[:message_type]).to eq('confirmation')
    expect($messaging.device).to eq(destination)

  end

  it "send error" do
    destination     = rand(9999999).to_s
    error           = rand(9999999).to_s
    time_stamp      = nil

    @handler.send_error(destination, time_stamp, error)

    expect($messaging.message[:message_type]).to eq('error')
    expect($messaging.device).to eq(destination)

  end

  it "handle message error" do

    err_snd         = true
    err_msg         = rand(9999999).to_s
    err_trc         = rand(9999999).to_s
    sender          = rand(9999999).to_s
    time_stamp      = nil

    @handler.handle_message_error(err_snd, sender, time_stamp, err_msg, err_trc)

    expect($messaging.message[:message_type]).to eq('error')
    expect($messaging.message[:error]).to eq(" #{err_msg} @ #{err_trc}")
    expect($messaging.device).to eq(sender)
  end

end
