require 'spec_helper'

describe MessageHandler do
  let(:bot) { FakeBot.new }
  let(:mesh) { FakeMesh.new }
  let(:message) do
    { 'fromUuid' => '1234567890',
      'payload'  => { 'message_type' => 'test_message' } }
  end
  let(:handler) { MessageHandler.new(message, bot, mesh) }

  it "initializes" do
    expect(handler.bot).to eq(bot)
    expect(handler.mesh).to eq(mesh)
    expect(handler.message).to be_kind_of(MeshMessage)
    expect(handler.message.from).to eq('1234567890')
    expect(handler.message.type).to eq('test_message')
    expect(handler.message.payload).to eq(message['payload'])
  end
end
