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

end
