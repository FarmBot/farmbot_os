require 'spec_helper'

describe FarmBotPi do
  let(:bot) { FakeBot.new }
  let(:stat_store) { FBPi::StatusStorage.new(Tempfile.new('fbpi')) }
  let(:mesh) { FakeMesh.new }
  let(:decorator) do
    FBPi::BotDecorator.build(bot,
                             stat_store,
                             mesh)
  end

  it 'associates the appropriate attrbiutes on build()' do
    expect(decorator).to be_kind_of(FBPi::BotDecorator)
    expect(decorator.mesh).to be(mesh)
    expect(decorator.__getobj__).to be(bot)
    expect(decorator.status_storage).to be(stat_store)
  end

  it 'states that it is ready' do
    decorator.ready
    msg = decorator.mesh.last.payload
    binding.pry
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
end
