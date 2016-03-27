require 'spec_helper'

describe FarmBotPi do
  let(:bot) { FakeBot.new }
  it "initializes" do
    pending("No longer relevant (and wasn't a good test to begin with).")
    expect(bot.credentials).to be_kind_of(FBPi::Credentials)
    expect(bot.mesh).to be_kind_of(EM::MeshRuby)
    expect(bot.status_storage).to be_kind_of(FBPi::StatusStorage)
    expect(bot.bot).to be_kind_of(FBPi::BotDecorator)
  end
end
