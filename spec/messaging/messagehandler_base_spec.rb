require 'spec_helper'
#require './lib/messaging/messaging.rb'
require './lib/messaging/messagehandler_base.rb'
require './lib/messaging/messagehandler_message.rb'

describe MessageHandlerBase do


  before do
    messaging = MessagingTest.new
    messaging.reset

    @handler = MessageHandlerBase.new(messaging)
  end

  it "hanlde message" do
    message = MessageHandlerMessage.new
    message.handled = false
    @handler.handle_message(message)
    expect(message.handled).to eq(false)        
  end

  it "hanlde message test message" do
    message = MessageHandlerMessage.new
    message.message_type = 'test'
    message.handled = false
    @handler.handle_message(message)
    expect(message.handled).to eq(true)        
  end


end
