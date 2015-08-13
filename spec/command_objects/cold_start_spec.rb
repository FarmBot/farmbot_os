require 'spec_helper'

describe FBPi::ColdStart do
  let(:bot) { FakeBot.new }

  it 'logs incoming GCodes' do
    pending
    msg = FB::Gcode.new { "R2 A1 B2" }
    logger = decorator.__getobj__.logger
    decorator.botmessage(msg)
    expect(logger.message).to eq("done R2 A1 B2")
  end

  it 'loads previous state from PStore' do
    pending
    pstore = decorator.status_storage
    pstore.transaction do
      pstore[:X] = 987654321
    end
    decorator.load_previous_state
    expect(decorator.status[:x]).to eq(987654321)
  end

  it 'cleanly disconnects' do
    pending
    decorator.status.transaction { |s| s[:X] = 9898 }
    allow(EM).to receive(:stop)
    decorator.close
    # Calls EM.stop
    expect(EM).to have_received(:stop)
    # Offloads bot status into the PStore
    expect(decorator.status_storage.to_h(:bot)[:X]).to eq(9898)
    # Logs the disconnection time.
    goodbye = decorator.mesh.last.params[:data]
    expect(goodbye).to include("Bot offline at #{Date.today}")
  end

  it 'does not log idle messages' do
    pending
    msg = FB::Gcode.new { "R00 A1" }
    logger = decorator.__getobj__.logger
    decorator.botmessage(msg)
    expect(logger.message).to eq("")
  end

  it 'cleanly disconnects' do
    pending
    decorator.status.transaction { |s| s[:X] = 9898 }
    allow(EM).to receive(:stop)
    decorator.close
    # Calls EM.stop
    expect(EM).to have_received(:stop)
    # Offloads bot status into the PStore
    expect(decorator.status_storage.to_h(:bot)[:X]).to eq(9898)
    # Logs the disconnection time.
    goodbye = decorator.mesh.last.params[:data]
    expect(goodbye).to include("Bot offline at #{Date.today}")
  end

  it 'transmits status diff messages' do
    pending
    decorator.diffmessage(X: 123)
    expect(decorator.status_storage.to_h(:bot)[:X]).to eq(123)
  end

end
