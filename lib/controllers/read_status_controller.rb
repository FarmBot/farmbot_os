require_relative 'abstract_controller'

class ReadStatusController < AbstractController
  def call
    msg = {
      x:    bot.status[:x],
      y:    bot.status[:y],
      z:    bot.status[:z],
      busy: bot.status[:busy],
    }
    reply "read_status", msg
  end
end
