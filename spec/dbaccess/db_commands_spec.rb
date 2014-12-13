require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

  ## commands

#  def create_new_command(scheduled_time, crop_id)
#    @commands.create_new_command(scheduled_time, crop_id)
#  end

#  def add_command_line(action, x = 0, y = 0, z = 0, speed = 0, amount = 0, pin_nr = 0, value1 = 0, value2 = 0, mode = 0, time = 0, external_info = "")
#    @commands.add_command_line(action, x, y, z, speed, amount, pin_nr, value1, value2, mode, time, external_info)
#  end

#  def fill_in_command_line_coordinates(line, action, x, y, z, speed)
#    @commands.fill_in_command_line_coordinates(line, action, x, y, z, speed)
#  end

#  def fill_in_command_line_pins(line, pin_nr, value1, value2, mode, time)
#    @commands.fill_in_command_line_pins(line, pin_nr, value1, value2, mode, time)
#  end

#  def fill_in_command_line_extra(line, amount = 0, external_info = "")
#    @commands.fill_in_command_line_extra(line, amount = 0, external_info = "")
#  end

#  def save_new_command
#    @commands.save_new_command
#    @refreshes.increment_refresh
#  end

#  def clear_schedule
#    @commands.clear_schedule
#  end

#  def clear_crop_schedule(crop_id)
#    @commands.clear_crop_schedule(crop_id)
#  end

#  def get_command_to_execute
#    @commands.get_command_to_execute
#  end

#  def set_command_to_execute_status(new_status)
#    @commands.set_command_to_execute_status(new_status)
#  end

end
