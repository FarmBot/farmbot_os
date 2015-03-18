require 'spec_helper'
require './lib/handlers/messagehandler.rb'
require './lib/handlers/messagehandler_base.rb'
require './lib/handlers/messagehandler_message.rb'

describe MessageHandlerBase do
  let(:message_handler) { MessageHandler.new(StubMessenger.new) }
  let(:handler) { MessageHandlerBase.new(StubMessenger.new) }

  it "handles messages" do
    message = MessageHandlerMessage.new({}, message_handler)
    message.handled = false
    handler.handle_message(message)
    expect(message.handled).to eq(false)
  end

  it "handles test messages" do
    message = MessageHandlerMessage.new({}, message_handler)
    message.message_type = 'test'
    message.handled = false
    handler.handle_message(message)
    expect(message.handled).to eq(true)
  end


end
