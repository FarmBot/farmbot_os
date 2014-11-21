require 'bson'
require 'sqlite3'
require 'active_record'

require './app/models/command.rb'
require './app/models/command_line.rb'

# retrieving and inserting commands into the schedule queue for the farm bot
# using sqlite

# Access class for the database

class DbAccessCommands

  attr_writer :dbaccess

  def initialize
    @last_command_retrieved = nil
    @new_command = nil
  end

  ## commands

  def create_new_command(scheduled_time, crop_id)
    @new_command = Command.new
    @new_command.scheduled_time = scheduled_time
    @new_command.crop_id = crop_id
    @new_command.status = 'creating'
    $db_write_sync.synchronize do
      @new_command.save
    end
  end

  def add_command_line(action, x, y, z, speed, amount, pin_nr, value1, value2, mode, time, external_info)
    if @new_command != nil
      line = CommandLine.new
      fill_in_command_line_coordinates(line, action, x, y, z, speed)
      fill_in_command_line_pins(line, pin_nr, value1, value2, mode, time)
      fill_in_command_line_extra(line, amount, external_info = "")
      $db_write_sync.synchronize do
        line.save
      end
    end
  end

  def fill_in_command_line_coordinates(line, action, x, y, z, speed)
    line.action        = action
    line.coord_x       = x
    line.coord_y       = y
    line.coord_z       = z
    line.speed         = speed
  end

  def fill_in_command_line_pins(line, pin_nr, value1, value2, mode, time)
    line.pin_nr        = pin_nr
    line.pin_value_1   = value1
    line.pin_value_2   = value2
    line.pin_mode      = mode
    line.pin_time      = time
  end

  def fill_in_command_line_extra(line, amount = 0, external_info = "")
    line.command_id    = @new_command.id
    line.amount        = amount
    line.external_info = external_info
  end


  def save_new_command
    if @new_command != nil
      @new_command.status = 'scheduled'
      $db_write_sync.synchronize do
        @new_command.save
      end
    end
  end

  def clear_schedule
    Command.where("status = ? AND scheduled_time IS NOT NULL",'scheduled').find_each do |cmd|
      $db_write_sync.synchronize do
        cmd.delete
      end
    end
  end

  def clear_crop_schedule(crop_id)
    Command.where("status = ? AND scheduled_time IS NOT NULL AND crop_id = ?",'scheduled',crop_id).find_each do |cmd|
      $db_write_sync.synchronize do
        cmd.delete
      end
    end
  end

  def get_command_to_execute
    @last_command_retrieved = Command.where("status = ? ",'scheduled').order('scheduled_time ASC').last
    @last_command_retrieved
  end

  def set_command_to_execute_status(new_status)
    if @last_command_retrieved != nil
      @last_command_retrieved.status = new_status
      $db_write_sync.synchronize do
        @last_command_retrieved.save
      end
    end
  end

end
