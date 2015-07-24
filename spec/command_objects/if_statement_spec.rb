require 'spec_helper'

describe FBPi::IfStatement do
  let(:bot) { FakeBot.new }
  let(:sequence) { Sequence.create }
  after(:each) do
    Sequence.destroy_all
    Step.destroy_all
  end
  it "handles statements that evaluate to true" do
    allow(sequence).to receive(:exec).with(bot)
    result = FBPi::IfStatement.run!(lhs:      "this",
                                    rhs:      "that",
                                    operator: "!=",
                                    bot:      bot,
                                    sequence: sequence)
    expect(sequence).to have_received(:exec)
  end

  it "handles statements that evaluate to false" do
    allow(sequence).to receive(:exec).with(bot)
    result = FBPi::IfStatement.run!(lhs:      "this",
                                    rhs:      "that",
                                    operator: "==",
                                    bot:      bot,
                                    sequence: sequence)
    expect(sequence).not_to have_received(:exec)
  end
end
