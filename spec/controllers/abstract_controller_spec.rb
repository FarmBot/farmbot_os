require 'spec_helper'

describe FBPi::AbstractController do
  let(:bot) { FakeBot.new }
  let(:mesh) { FakeMesh.new }
  let(:message) { FBPi::MeshMessage.new(
    id: '1234567890', method: 'sync_sequence')}
  let(:ctrl) { FBPi::AbstractController.new(message, bot, mesh) }

  it "initializes" do
    expect(ctrl.bot).to eq(bot)
    expect(ctrl.mesh).to eq(mesh)
    expect(ctrl.message).to eq(message)
  end

  it 'executes a reply()' do
    ctrl = FBPi::AbstractController.new(message, bot, mesh)
    allow(FBPi::SendMeshResponse).to receive(:run!).with(mesh: mesh,
      method: "HELLO!", result: {}, original_message: message)
    ctrl.reply("HELLO!", {})
    expect(FBPi::SendMeshResponse).to have_received(:run!)
  end
end
