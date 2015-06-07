require 'spec_helper'

describe FBPi::ChoreRunner do
  let(:schedules) { [FakeSchedule.new] }
  let(:bot) { FakeBot.new }
  let(:runner) { FBPi::ChoreRunner.new(bot) }

  it 'has schedules' do
    sched = runner.schedules
    expect(sched).to be_kind_of(Array)
  end

  it 'lets you know theres nothing to run' do
    runner.nothing
    expect(bot.logger.message).to eq("Nothing to run this cycle. Waiting an "\
                                     "additional 60 secs.")
  end

  it 'runs a ChoreRunner on the schedules, if there is `something` to run' do
    results = Struct.new(:bot, :schedule).new
    allow(FBPi::ScheduleChore).to receive(:run) do |schedule, bot|
      results.bot, results.schedule = bot, schedule
    end
    allow(runner).to receive(:schedules) { schedules }
    runner.something

    expect(results.bot).to eq(bot)
    expect(results.schedule).to eq(schedules.first)
  end

  it 'runs `something()` if schedules are present' do
    allow(runner).to receive(:schedules) { schedules }
    allow(runner).to receive(:something)
    allow(runner).to receive(:nothing)
    runner.run
    expect(runner).to have_received(:something)
    expect(runner).to_not have_received(:nothing)
  end

  it 'runs `nothing()` if schedules are present' do
    allow(runner).to receive(:schedules) { [] }
    allow(runner).to receive(:something)
    allow(runner).to receive(:nothing)
    runner.run
    expect(runner).to have_received(:nothing)
    expect(runner).to_not have_received(:something)
  end
end
