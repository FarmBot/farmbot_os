require_relative '../command_objects/exec_step'
class Step < ActiveRecord::Base
  attr_accessor :command

  COMMANDS = %w(emergency_stop home_all home_x home_y home_z move_absolute
  move_relative pin_write read_parameter read_status write_parameter wait
  send_message if_statement read_pin)

  belongs_to :sequence

  def execute(bot)
    FBPi::ExecStep.run!(bot: bot, step: self)
  rescue SystemStackError; bot.log("Endless loop in '#{sequence.name}'.")
  end
end
