require 'mutations'

module FBPi
  # Excutes a step in "The Real World(tm)".
  class ExecStep < Mutations::Command
    class UnsafeCommand < Exception; end

    required do
      duck :step, methods: [:message_type, :x, :y, :z, :pin, :value, :mode]
      duck :bot, methods: [:commands, :current_position]
    end

    def execute
      self.send(message_key)
    rescue UnsafeCommand; self.send(:unknown)
    end

    def message_key
      msg = step.message_type.to_s
      raise UnsafeCommand,
        "Unknown sequence step '#{msg}'" if !Step::COMMANDS.include?(msg)
      raise UnsafeCommand,
        "Step '#{msg}' is allowed, but not yet implemented" if !respond_to?(msg)
      msg
    end

    def move_relative
      bot.commands.move_relative(x: (step.x || 0),
                                 y: (step.y || 0),
                                 z: (step.z || 0))
    end

    def move_absolute
      bot.commands.move_absolute(x: step.x || bot.current_position.x,
                                 y: step.y || bot.current_position.y,
                                 z: step.z || bot.current_position.z)
    end

    def pin_write
      bot.commands.pin_write(pin: step.pin, value: step.value, mode: step.mode)
    end

    def wait
      # TODO: Yes, this is horrible. Ideally, I would like to use Fibers that
      # can be paused / resumed using EventMachine timers, but I am holding off
      # on that for now. Pull requests are welcome. Contact me for details.
      # Possibly relevant: http://www.rubydoc.info/github/igrigorik
      #                    /em-synchrony/EventMachine%2FSynchrony.sleep
      # -- rickcarlino
      sleep((step.value || 0) / 1000.0)
    end

    def send_message
      FBPi::SendMessage.run!(message: step.value, bot: bot)
    end

    def unknown
      bot.log("Unknown message #{step.message_type}")
    end
  end
end
