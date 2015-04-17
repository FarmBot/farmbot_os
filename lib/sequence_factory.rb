require 'mutations'
require 'ostruct'
#  ______   ___   ___     ___
# |      | /   \ |   \   /   \  __
# |      ||     ||    \ |     ||  | This file is a work in progress. Needs:
# |_|  |_||  O  ||  D  ||  O  ||__|  * Break down into individual files
#   |  |  |     ||     ||     | __   * Remove case statement SequenceStep#call()
#   |  |  |     ||     ||     ||  |  * DRY StepValidator::COMMANDS into 1 place.
#   |__|   \___/ |_____| \___/ |__|

class SequenceStep < OpenStruct
  def initialize(hash = nil)
    super
    self[:command] = OpenStruct.new(self[:command])
  end

  def call(bot)
    botcmd, cmd = bot.commands, command
    case message_type
    when "move_relative"
      coords = {x: cmd.x || 0, y: cmd.y || 0, z: cmd.z || 0}
      botcmd.move_relative(coords)
    when "move_absolute"
      coords = {x: cmd.x || bot.current_position.x,
                y: cmd.y || bot.current_position.y,
                z: cmd.z || bot.current_position.z}
      botcmd.move_absolute(coords)
    when "pin_write"
      botcmd.pin_write(pin: cmd.pin, value: cmd.value, mode: cmd.mode)
    else
      bot.log "Unknown message #{message_type}"
    end
  end
end

# Builds a validated sequence (and collection of steps)
class SequenceFactory < Mutations::Command
  class StepValidator < Mutations::Command
    COMMANDS = %w(emergency_stop home_all home_x home_y home_z move_absolute
      move_relative pin_write read_parameter read_status write_parameter)

    required do
      string :message_type, in: COMMANDS
      hash :command do
        optional do
          [:x, :y, :z, :speed, :pin, :value, :mode].each do |f|
            integer f, default: nil
          end
        end
      end
    end

    def execute
      SequenceStep.new(inputs)
    end
  end

  required do
    string :name
    array(:steps) { model :sequence_step, builder: StepValidator }
  end

  def execute
    OpenStruct.new(inputs)
  end
end
