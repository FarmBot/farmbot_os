require 'spec_helper'
require_relative '../../lib/command_objects/send_message'

describe FBPi::SendMessage do
  let(:bot) { FakeBot.new }
  let(:mesh) { FakeMesh.new }
  let(:message) do
    FBPi::SendMessage.run!(bot: bot, mesh: mesh, message: "{{ test_mode }}")
  end

  it "Allows users to template the current time" do
    expect(message[:data]).to include("this is is used to test templating.")
  end

  it 'pushes messages over messaging layer' do
    message
    expect(mesh.last.params[:data]).to eq("this is is used to test templating.")
  end
end
