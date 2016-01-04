require 'spec_helper'

describe FBPi::ReadStatusController do
  let(:bot) do
    bot = FakeBot.new
    bot.commands = FakeOutgoingHandler.new
    bot
  end
  let(:mesh) { FakeMesh.new }
  let(:message) do
    FBPi::MeshMessage.new(from:   '1234567890',
                          method: 'read_status')
  end
  let(:controller) { FBPi::ReadStatusController.new(message, bot, mesh) }

  it 'handles a call' do
    #       _______
    #     /` _____ `\;,
    #    /__(^===^)__\';,
    #      /  :::  \   ,;
    #     |   :::   | ,;'
    # jgs  '._______.'`

    controller.call
    msg = mesh.last.params
    expect(msg[:result][:method]).to eq("read_status")
    keys = msg[:result]
    [:BUSY, :LAST, :X, :Y, :Z].each do |key|
      expect(keys).to include(key)
    end
  end
end
