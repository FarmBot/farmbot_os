require 'spec_helper'
require './lib/messaging/messaging.rb'
require './lib/messaging/messagehandler_message.rb'

describe MessageHandlerBase do


  before do
    @handler = MessageHandlerBase.new
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
