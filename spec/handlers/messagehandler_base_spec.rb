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
    expect do
      handler.handle_message(message)
    end.to raise_error(RuntimeError)
  end

  it "handles test messages" do
    message = MessageHandlerMessage.new({}, message_handler)
    message.message_type = 'test'
    message.handled = false
    expect(handler.handle_message(message)).to include("?")
  end


end
