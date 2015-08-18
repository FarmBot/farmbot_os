require 'spec_helper'

describe Step do
  let(:bot) { FakeBot.new }
  let(:step) { Step.new(message_type: 'wrong') }

  it "handles unknown values" do
    step.execute(bot)
    expect(bot.logger.message).to eq("Unknown message wrong")
  end

end
