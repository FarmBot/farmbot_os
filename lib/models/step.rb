class Step < ActiveRecord::Base
  attr_accessor :bot, :command

  COMMANDS = %w(emergency_stop home_all home_x home_y home_z move_absolute
    move_relative pin_write read_parameter read_status write_parameter wait)

  belongs_to :sequence

  # TODO: Refactor this whole class. Right now, I'm just trying stuff out, but
  # this definitely needs to be in a command object.
  def execute(bot)
    r = {"move_relative" => :move_relative,
         "move_absolute" => :move_absolute,
         "pin_write"     => :pin_write,
         "unknown"       => :unknown,
         "wait"          => :wait}
    key = r[message_type.to_s] || :unknown
    puts "EXECUTING #{key}"
    self.send(key, bot)
  end

  def move_relative(bot)
    coords = {x: (x || 0), y: (y || 0), z: (z || 0)}
    bot.commands.move_relative coords
  end

  def move_absolute(bot)
    coords = { x: x || bot.current_position.x,
               y: y || bot.current_position.y,
               z: z || bot.current_position.z, }
    bot.commands.move_absolute(coords)
  end

  def pin_write(bot)
    bot.commands.pin_write(pin: pin, value: value, mode: mode)
  end

  def wait(bot)
    # TODO: Yes, this is horrible. Ideally, I would like to use Fibers that can
    # be paused / resumed using EventMachine timers, but I am holding off on
    # that for now. Pull requests are welcome. Contact me for details.
    # Possibly relevant: http://www.rubydoc.info/github/igrigorik
    #                    /em-synchrony/EventMachine%2FSynchrony.sleep
    # -- rickcarlino
    seconds = (value || 0) / 1000.0
    actual  =
    puts "Starting #{seconds} second wait"
    early = Time.now
    sleep(millis)
    late = Time.now
    puts "Ending #{seconds} second wait."
    puts "Actual time: #{late - early}"
  end

  def unknown(bot)
    bot.log("Unknown message #{message_type}")
  end
end
