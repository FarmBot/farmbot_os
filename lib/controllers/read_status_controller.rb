require_relative 'abstract_controller'

class ReadStatusController < AbstractController
  def call
    reply "read_status", x: bot.status[:x], y: bot.status[:y],
                         z: bot.status[:z], busy: bot.status[:busy],
                         current_command:  bot.status[:last]
  end
end
