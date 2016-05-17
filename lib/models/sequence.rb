# References a collection of steps that the bot will execute, eg: "Plant tomato
# seeds". Sequences are stored procedures that are executed in the real world at
# a specified time (through the use of Schedule objects) or immediately.
class Sequence < ActiveRecord::Base
  has_many :schedules
  has_many :steps, dependent: :destroy

  def exec(bot)
    steps
      .sort{ |a, b| a.position <=> b.position}
      .map { |step| step.execute(bot) }
  end

  def try_exec(bot)
    begin
      SyncBot.run!(bot: bot)
    rescue
      puts 'WARN: Could not sync sequences.'
    end
  end
end
