class Step < OpenStruct
  attr_accessor :bot

  def initialize(hash = nil)
    super
    self[:command] = OpenStruct.new(self[:command])
  end

  def execute(bot)
    @bot = bot
    route_me = { "move_relative" => -> { move_relative },
                 "move_absolute" => -> { move_absolute },
                 "pin_write"     => -> { pin_write }, }
    route_me[message_type][] || bot.log("Unknown message #{message_type}")
  end

  def move_relative
    coords = {x: (command.x || 0), y: (command.y || 0), z: (command.z || 0)}
    bot.commands.move_relative coords
  end

  def move_absolute
    coords = { x: command.x || bot.current_position.x,
               y: command.y || bot.current_position.y,
               z: command.z || bot.current_position.z, }
    bot.commands.move_absolute(coords)
  end

  def pin_write
    bot.commands.pin_write(pin: command.pin, value: command.value, mode: command.mode)
  end
end
