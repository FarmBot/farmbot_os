require 'spec_helper'

describe FBPi::BotDecorator do
  let(:bot) { FakeBot.new }
  let(:decorator) { FBPi::BotDecorator.new(bot) }

  it 'associates the appropriate attributes on build()' do
    expect(decorator.__getobj__).to eq(bot)
  end
end
