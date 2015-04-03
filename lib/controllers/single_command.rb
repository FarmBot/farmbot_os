require_relative 'abstract_controller'

class SingleCommandController < AbstractController
  attr_reader :cmd

  AVAILABLE_ACTIONS = {"move relative" => :move_relative,
                       "unknown"       => :unknown}

  def call
    @cmd   = message.payload["command"]
    action = AVAILABLE_ACTIONS[cmd["action"].to_s.downcase] || 'unknown'
    send(action)
  end

  def move_relative
    bot.commands.move_relative x: cmd['x'], y: cmd['y'], z: cmd['z']
  end

  def unknown
    raise "Unknown message. TODO: Fix this."
  end
end
