require_relative 'abstract_controller'

module FBPi
  class SingleCommandController < AbstractController
    attr_reader :cmd, :key

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
      # "single_command.MOVE RELATIVE" ==> "move relative"
      @key   = message.method.to_s.split('.').last.downcase.gsub("_", " ")
      action = AVAILABLE_ACTIONS.fetch(key, :unknown).to_sym
      @cmd   = message.params
      send(action)
      reply 'single_command', cmd
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
      bot.status.set_pin(cmd['pin'], cmd['value1']) # Belongs in FB-Serial
      bot.commands.pin_write pin:   cmd['pin'],
                             value: cmd['value1'],
                             mode:  cmd['mode'] || 0
    end

    def emergency_stop
      bot.commands.emergency_stop
    end

    def unknown
      case key
      when 'single command', nil then msg = 'NULL'
      else; msg = key
      end
      raise "Unknown message '#{ msg }'. Most likely, the "\
            "command has not been implemented or does not exist. Try: "\
            "#{AVAILABLE_ACTIONS.keys.join(', ')}"
    end
  end
end
