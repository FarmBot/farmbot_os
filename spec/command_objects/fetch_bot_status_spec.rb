require 'spec_helper'

describe FBPi::FetchBotStatus do
  let(:bot) { FakeBot.new }
  let(:obj) { FBPi::FetchBotStatus.new(bot: bot) }

  it "reads pins" do
    expect(bot.commands).to receive(:read_pin).exactly(14).times
    obj.send(:read_pins)
  end

  it "reads parameters" do
    this_many = FBPi::FetchBotStatus::RELEVANT_PARAMETERS.count
    expect(bot.commands).to receive(:read_parameter).exactly(this_many).times
    obj.read_parameters
  end

  it "executes" do
    expect(obj).to receive(:read_pins)
    expect(obj).to receive(:read_parameters)
    expect(obj.execute).to eq(bot.status.to_h)
  end
end
