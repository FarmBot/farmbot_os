require 'spec_helper'

describe ChoreRunner do
  let(:bot) { FakeBot.new }
  let(:runner) { ChoreRunner.new(bot) }

  it 'has schedules' do
    sched = runner.schedules
    expect(sched).to be_kind_of(Array)
  end

  it 'lets you know theres nothing to run' do
    runner.nothing
    expect(bot.logger.message).to eq("Nothing to run this cycle. Waiting an additional 60 secs.")
  end
end
