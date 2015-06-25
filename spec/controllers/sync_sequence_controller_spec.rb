require 'spec_helper'

describe FBPi::SyncSequenceController do
  let(:bot) { FakeBot.new }
  let(:mesh) { FakeMesh.new }
  let(:message) do
    FBPi::MeshMessage.new from:   '1234567890',
                          method: 'sync_sequence'
  end
  let(:controller) { FBPi::SyncSequenceController.new(message, bot, mesh) }

  it "initializes" do
    controller.call
    msg = mesh.last.params || {}
    raise msg[:error] if msg[:error]
    expect(mesh.last.method).to eq("sync_sequence")
  end
end
