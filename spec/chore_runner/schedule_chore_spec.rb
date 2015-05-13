require 'spec_helper'

describe ScheduleChore do
  let(:bot) { FakeBot.new }
  let(:now) { Time.now }
  let(:schedule) do
    Schedule.new(end_time: (now + 4.hours), time_unit: 'hourly', repeat: '1')
  end
  let(:chore) { ScheduleChore.new(schedule, bot, now) }

  it 'knows if the schedule is expired' do
    schedule.end_time = now + 4.hours
    expect(chore.expired?).to be_falsey

    schedule.end_time = now - 4.hours
    expect(chore.expired?).to be_truthy
  end

  it 'knows when the next_time is' do
    expect(chore.next_time).to eq(now + 1.hour)
  end

  it 'bumps the execution time' do
    expect(schedule.next_time).to be_nil
    chore.bump_execution_time
    expect(schedule.next_time).to eq(now + 1.hour)
  end

  it 'performs each step' do
    seq = FakeSequence.new
    allow(schedule).to receive(:sequence) { seq }
    schedule.sequence.steps.each do |stp|
      expect(stp.called?).to be_falsey
      expect(stp.bot).to be_nil
    end

    chore.perform_steps

    schedule.sequence.steps.each do |stp|
      expect(stp.called?).to be_truthy
      expect(stp.bot).to be(bot)
    end
  end
end
