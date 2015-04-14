require_relative 'abstract_controller'

class SingleCommandController < AbstractController
  attr_reader :cmd

  AVAILABLE_ACTIONS = { "move relative"   => :move_relative,
                        "move absolute"   => :move_absolute,
                        "unknown"         => :unknown,
                        "home x"          => :home_x,
                        "home y"          => :home_y,
                        "home z"          => :home_z,
                        "home all"        => :home_all,
                        "pin write"       => :pin_write,
                        "emergency stop"  => :emergency_stop, }

  def call
    @cmd   = message.payload["command"]
    action = AVAILABLE_ACTIONS[cmd["action"].to_s.downcase] || :unknown
    puts "Calling #{action}"
    send(action)
    reply "read_status", confirmation: true, command: cmd
  end

  def move_relative
    bot.commands.move_relative x: cmd['x'], y: cmd['y'], z: cmd['z']
  end

  def move_absolute
    bot.commands.move_absolute x: cmd['x'], y: cmd['y'], z: cmd['z']
  end

  def home_x
    bot.commands.home_x
  end

  def home_y
    bot.commands.home_y
  end

  def home_z
    bot.commands.home_z
  end

  def home_all
    bot.commands.home_all
  end

  def pin_write
    bot.commands.pin_write pin:   cmd['pin'],
                           value: cmd['value1'],
                           mode:  cmd['mode'] || 0
  end

  def emergency_stop
    bot.commands.emergency_stop
  end

  def unknown
    raise "Unknown message. Most likely, the command has not been implemented "\
          "or does not exist."
  end
end
