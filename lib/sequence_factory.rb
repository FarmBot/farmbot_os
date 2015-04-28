require 'mutations'
require 'ostruct'
#  ______   ___   ___     ___
# |      | /   \ |   \   /   \  __
# |      ||     ||    \ |     ||  | This file is a work in progress. Needs:
# |_|  |_||  O  ||  D  ||  O  ||__|  * Break down into individual files
#   |  |  |     ||     ||     | __   * Remove case statement SequenceStep#call()
#   |  |  |     ||     ||     ||  |  * DRY StepValidator::COMMANDS into 1 place.
#   |__|   \___/ |_____| \___/ |__|  * Find a way to re-use single_command controller?

class SequenceStep < OpenStruct
  attr_accessor :bot

  def initialize(hash = nil)
    super
    self[:command] = OpenStruct.new(self[:command])
  end

  def call(bot)
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

# Builds a validated sequence (and collection of steps)
class SequenceFactory < Mutations::Command
  required do
    string :name
    array(:steps) { model :sequence_step, builder: StepValidator }
  end

  def execute
    OpenStruct.new(inputs)
  end
end
