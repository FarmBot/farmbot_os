require_relative 'schedule_chore'
module FBPi
  class ChoreRunner
    INTERVAL = 60 # seconds
    attr_accessor :schedules, :bot

    def initialize(bot)
      @bot = bot
    end

    def run
      schedules.present? ? something : nothing
    end

    def something
      schedules.each { |s| ScheduleChore.run(s, bot) }
    end

    def nothing
      bot.log "Nothing to run this cycle. Waiting an additional #{INTERVAL}"\
              " secs."
    end

    def schedules
      @schedules ||= ( Schedule.where(next_time: nil).to_a +           # New
                       Schedule.where("next_time < ?", Time.now).to_a )# Overdue
    end
  end
end
