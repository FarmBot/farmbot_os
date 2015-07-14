require 'spec_helper'
require_relative '../../lib/command_objects/send_message'

describe FBPi::SendMessage do
  let(:bot) { FakeBot.new }
  let(:message) do
    FBPi::SendMessage.run!(bot: bot, message: "Last command: {{ last }}")
  end

  it "Allows users to template variables" do
    expect(message[:data]).to include("Last command:")
    expect(message[:data]).to include("none")
  end

  it 'pushes messages over messaging layer' do
    message
    expect(bot.mesh.last.params[:data]).to include("none")
  end
end
