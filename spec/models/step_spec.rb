require 'spec_helper'

describe Step do
  let(:bot) { FakeBot.new }
  it "handles unknown values" do
    step = Step.new(message_type: 'wrong')
    step.execute(bot)
    expect(bot.logger.message).to eq("Unknown message wrong")
  end
end
