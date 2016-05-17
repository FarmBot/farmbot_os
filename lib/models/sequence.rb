require_relative "../command_objects/sync_bot"
# References a collection of steps that the bot will execute, eg: "Plant tomato
# seeds". Sequences are stored procedures that are executed in the real world at
# a specified time (through the use of Schedule objects) or immediately.
class Sequence < ActiveRecord::Base
  has_many :schedules
  has_many :steps, dependent: :destroy

  def exec(bot)
    try_sync(bot)
    steps
      .sort{ |a, b| a.position <=> b.position}
      .map { |step| step.execute(bot) }
  end

  def try_sync(bot)
    begin
      FBPi::SyncBot.run!(bot: bot)
    rescue => e
      puts 'WARN: Could not sync sequences.'
      puts e.class
      puts e.message
    end
  end
end
