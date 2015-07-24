require 'spec_helper'

describe FBPi::MessageHandler do
  let(:bot) { FakeBot.new }
  let(:mesh) { FakeMesh.new }
  let(:message) do
    { 'fromUuid' => '1234567890',
      'method'   => 'test_message'  }
  end
  let(:handler) { FBPi::MessageHandler.new(message, bot, mesh) }

  it 'initializes' do
    expect(handler.bot).to eq(bot)
    expect(handler.mesh).to eq(mesh)
    expect(handler.message).to be_kind_of(FBPi::MeshMessage)
    expect(handler.message.from).to eq('1234567890')
    expect(handler.message.method).to eq('test_message')
    expect(handler.message.params).to eq({})
  end

  it 'Calls itself when provided a bot, message and mesh network' do
    hndlr = FBPi::MessageHandler.call(message, bot, mesh)
    msgs  = mesh.all
    expect(msgs.count).to eq(1)
    expect(msgs.first.method).to eq('error')
  end

  it 'sends errors' do
    begin
      raise 'Fake error for testing'
    rescue => fake_error
      handler.send_error(fake_error)
      expect(mesh.last.params[:error][:message])
        .to include('Fake error for testing')
    end
  end

  it 'catches errors' do
      handler
      handler.message.method = {cause_errors: "because not a string anymore"}
      handler.call
      expect(mesh.all.any?).to be_truthy
      results = mesh.last.results
      expect(results[:method]).to eq("error")
      expect(results[:message]).to eq("Method isn't a string")
  end
end
