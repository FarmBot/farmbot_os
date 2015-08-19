require 'mutations'

module FBPi
  # Excutes a single step in "The Real World(tm)". This command will be called
  # multiple times by a single schedule object when it is executed at a
  # prescribed time.
  class ExecStep < Mutations::Command
    class UnsafeCommand < Exception; end

    required do
      duck :step, methods: [:message_type, :x, :y, :z, :pin, :value, :mode]
      duck :bot, methods: [:commands, :current_position]
    end

    def execute
      self.send(message_key)
    rescue UnsafeCommand; unknown
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
      bot.commands.write_pin(pin: step.pin, value: step.value, mode: step.mode)
    end


    def send_message
      SendMessage.run! message: step.value, bot: bot
    end

    def if_statement
      IfStatement.run! lhs:      bot.template_variables[step.variable],
                       rhs:      step.value,
                       operator: step.operator,
                       bot:      bot,
                       sequence: Sequence.find_by(id_on_web_app:
                                                  step.sub_sequence_id)
    end

    def unknown
      bot.log("Unknown message #{step.message_type}")
    end

    def read_pin
      ReadPin.run!(bot: bot, pin: step.pin)
    end

    def wait
      # TODO: Yes, this is horrible. Ideally, I would like to use Fibers that
      # can be paused / resumed using EventMachine timers, but I am holding off
      # on that for now. Pull requests are welcome. Contact me for details.
      # Possibly relevant: http://www.rubydoc.info/github/igrigorik
      #                    /em-synchrony/EventMachine%2FSynchrony.sleep
      # -- rickcarlino
      sleep((step.value.to_f || 0) / 1000.0)
    end
  end
end
