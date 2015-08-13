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
    pending "Finish this tomorrow."
    binding.pry
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

  it 'does not log idle messages' do
    msg = FB::Gcode.new { "R00 A1" }
    logger = bot.logger
    obj.botmessage(msg)
    expect(logger.message).to eq("")
  end

  it 'transmits status diff messages' do
    obj.diffmessage(X: 123)
    expect(bot.status_storage.to_h(:bot)[:X]).to eq(123)
  end

end
