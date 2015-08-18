require 'spec_helper'

describe FarmBotPi do
  let(:bot) { FakeBot.new }
  it "initializes" do
    expect(subject.credentials).to be_kind_of(FBPi::Credentials)
    expect(subject.mesh).to be_kind_of(EM::MeshRuby)
    expect(subject.status_storage).to be_kind_of(FBPi::StatusStorage)
    expect(subject.bot).to be_kind_of(FBPi::BotDecorator)
  end
end
