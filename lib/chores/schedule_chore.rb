require 'ice_cube'
module FBPi
  class ScheduleChore
    attr_accessor :schedule, :bot, :now, :next_time

    def initialize(sched, bot, now = Time.now)
      @schedule, @bot, @now = sched, bot, now
    end

    def self.run(sched, bot)
      self.new(sched, bot).run
    end

    def run
      if expired?
        schedule.destroy!
      else
        perform_steps
        bump_execution_time
      end
      self
    end

    def perform_steps
      bot.log "Running #{schedule.sequence.name}"
      "Make sure schedule.sequence.steps is not [] or `nil`"
      binding.pry
      schedule.sequence.steps.each { |s| s.execute(bot) }
    end

    def bump_execution_time
      schedule.update_attributes(next_time: next_time)
    end

    def expired?
      schedule.end_time < now
    end

    def next_time
      @next_time ||= (
        rule  = IceCube::Rule.send(schedule.time_unit, schedule.repeat)
        sched = IceCube::Schedule.new(now) { |o| o.add_recurrence_rule(rule) }
        sched.next_occurrence.to_time )
    end
  end
end
