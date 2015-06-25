require 'spec_helper'

describe FarmBotPi do
  let(:stat_store) { FBPi::StatusStorage.new(Tempfile.new('fbpi')) }
  let(:mesh) { FakeMesh.new }
  let(:decorator) do
    FBPi::BotDecorator.build(stat_store,
                             mesh,
                             FakeRestClient.new,
                             FakeBot)
  end
  let(:bot) { decorator.__getobj__ }
  it 'associates the appropriate attrbiutes on build()' do
    expect(decorator).to be_kind_of(FBPi::BotDecorator)
    expect(decorator.mesh).to be(mesh)
    expect(decorator.__getobj__).to be(bot)
    expect(decorator.status_storage).to be(stat_store)
  end

  it 'states that it is ready' do
    decorator.ready
    msg = decorator.mesh.last.params
    expect(msg[:data]).to include("Online at #{Date.today}")
  end

  it 'logs incoming GCodes' do
    msg = FB::Gcode.new { "R2 A1 B2" }
    logger = decorator.__getobj__.logger
    decorator.botmessage(msg)
    expect(logger.message).to eq("done R2 A1 B2")
  end

  it 'does not log idle messages' do
    msg = FB::Gcode.new { "R00 A1" }
    logger = decorator.__getobj__.logger
    decorator.botmessage(msg)
    expect(logger.message).to eq("")
  end

  it 'loads previous state from PStore' do
    pstore = decorator.status_storage
    pstore.transaction do
      pstore[:X] = 987654321
    end
    decorator.load_previous_state
    expect(decorator.status[:x]).to eq(987654321)
  end

  it 'transmits status diff messages' do
    decorator.diffmessage(X: 123)
    expect(decorator.status_storage.to_h[:X]).to eq(123)
  end

  it 'cleanly disconnects' do
    decorator.status.transaction { |s| s[:X] = 9898 }
    allow(EM).to receive(:stop)
    decorator.close
    # Calls EM.stop
    expect(EM).to have_received(:stop)
    # Offloads bot status into the PStore
    expect(decorator.status_storage.to_h[:X]).to eq(9898)
    # Logs the disconnection time.
    goodbye = decorator.mesh.last.params[:data]
    expect(goodbye).to include("Bot offline at #{Date.today}")
  end
end
