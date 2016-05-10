require 'spec_helper'

describe FBPi::ColdStart do
  let(:bot) { FakeBot.new }
  let(:obj) { FBPi::ColdStart.new(bot: bot) }

  it 'logs incoming GCodes' do
    msg = FB::Gcode.new { "R2 A1 B2" }
    logger = bot.logger
    obj.botmessage(msg)
    expect(logger.message).to eq("done R2 A1 B2")
  end

  it 'pulls up stored parameters from disk' do
    bot.status_storage.update_attributes(:bot, :PARAM_VERSION => 123)
    bot.status_storage.update_attributes(:bot, :Q => 1)
    expect(bot.status.to_h[:PARAM_VERSION]).to be_nil
    expect(bot.status.to_h[:Q]).to be_nil

    obj.pull_up_stored_parameters_from_disk

    expect(bot.status.to_h[:PARAM_VERSION]).to eq(123)
    expect(bot.status.to_h[:UNKNOWN_PARAMETER_Q]).to eq(1)
  end

  it 'sets event handlers' do
    expect(bot.mesh.socket.events[:ready]).to be_empty
    expect(bot.instance_variable_get(:@onmessage)).to be_nil
    expect(bot.instance_variable_get(:@onchange)).to be_nil
    expect(bot.instance_variable_get(:@onclose)).to be_nil
    obj.set_event_handlers
    expect(bot.mesh.socket.events[:ready].first).to be_kind_of(Proc)
    expect(bot.instance_variable_get(:@onmessage)).to be_kind_of(Proc)
    expect(bot.instance_variable_get(:@onchange)).to be_kind_of(Proc)
    expect(bot.instance_variable_get(:@onclose)).to be_kind_of(Proc)
  end

  it 'executes' do
    allow(obj).to receive(:set_event_handlers)
    allow(obj).to receive(:pull_up_stored_parameters_from_disk)
    allow(FBPi::FetchBotStatus).to receive(:run!)

    obj.execute

    expect(obj).to have_received(:set_event_handlers)
    expect(obj).to have_received(:pull_up_stored_parameters_from_disk)
    expect(FBPi::FetchBotStatus).to have_received(:run!)
  end

  it 'cleanly disconnects' do
    bot.status.transaction { |s| s[:X] = 9898 }
    allow(EM).to receive(:stop)
    obj.close
    # Calls EM.stop
    expect(EM).to have_received(:stop)
    # Offloads bot status into the PStore
    expect(bot.status_storage.to_h(:bot)[:X]).to eq(9898)
    # Logs the disconnection time.
    goodbye = bot.logger.message
    expect(goodbye).to include("Bot offline at #{Date.today}")
  end

  it 'transmits status diff messages' do
    obj.diffmessage(X: 123)
    expect(bot.status_storage.to_h(:bot)[:X]).to eq(123)
  end

end
