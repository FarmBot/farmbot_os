require 'spec_helper'

describe FBPi::ReadPin do
  let(:bot) { FakeBot.new }

  it "Broadcasts the status of a pin over Mesh" do
    result = FBPi::ReadPin.run!(pin: 6, bot: bot)
    expect(result[:data]).to eq("Pin 6 is unknown")
  end
end
