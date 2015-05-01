class Step < ActiveRecord::Base
  attr_accessor :bot, :command

  COMMANDS = %w(emergency_stop home_all home_x home_y home_z move_absolute
    move_relative pin_write read_parameter read_status write_parameter)

  belongs_to :sequence

  def execute(bot)
    @bot = bot
    route_me = { "move_relative" => -> { move_relative },
                 "move_absolute" => -> { move_absolute },
                 "pin_write"     => -> { pin_write }, }
    route_me[message_type][] || bot.log("Unknown message #{message_type}")
  end

  def move_relative
    coords = {x: (x || 0), y: (y || 0), z: (z || 0)}
    bot.commands.move_relative coords
  end

  def move_absolute
    coords = { x: x || bot.current_position.x,
               y: y || bot.current_position.y,
               z: z || bot.current_position.z, }
    bot.commands.move_absolute(coords)
  end

  def pin_write
    bot.commands.pin_write(pin: pin, value: value, mode: mode)
  end
end
