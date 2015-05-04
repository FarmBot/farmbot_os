class Step < ActiveRecord::Base
  attr_accessor :bot, :command

  COMMANDS = %w(emergency_stop home_all home_x home_y home_z move_absolute
    move_relative pin_write read_parameter read_status write_parameter)

  belongs_to :sequence

  # TODO: Refactor this whole method. Probably too hard for a newcomer to
  # understand. If you need help with this one, raise an issue.
  def execute(bot)
    @bot = bot
    r = {"move_relative" => -> { move_relative },
         "move_absolute" => -> { move_absolute },
         "pin_write"     => -> { pin_write },
         "unknown"       => -> { bot.log("Unknown message #{message_type}") },}
    (r[message_type] || r['unknown']).call
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
