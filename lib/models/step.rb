require_relative '../command_objects/exec_step'
class Step < ActiveRecord::Base
  attr_accessor :command
  COMMANDS = %w(emergency_stop home_all home_x home_y home_z move_absolute
    move_relative pin_write read_parameter read_status write_parameter wait)

  belongs_to :sequence

  def execute(bot)
    FBPi::ExecStep.run!(bot: bot, step: self)
  end
end
