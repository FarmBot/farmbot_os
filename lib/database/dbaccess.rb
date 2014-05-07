require 'bson'
require 'sqlite3'
require 'active_record'

require './app/models/command.rb'
require './app/models/command_line.rb'
require './app/models/refresh.rb'

# retrieving and inserting commands into the schedule queue for the farm bot
# using sqlite

# Access class for the database

class DbAccess

  def initialize
    config = YAML::load(File.open('./config/database.yml'))
    ActiveRecord::Base.establish_connection(config["development"])

    @last_command_retrieved = nil
    @refresh_value = 0
    @refresh_value_new = 0

    @new_command = nil
  end

  def create_new_command(scheduled_time, crop_id)
    @new_command = Command.new
    @new_command.scheduled_time = scheduled_time
    @new_command.crop_id = crop_id
    @new_command.status = 'creating'
    @new_command.save
  end

  def add_command_line(action, x = 0, y = 0, z = 0, speed = 0, amount = 0)
    if @new_command != nil
      line = CommandLine.new
      line.action = action
      line.coord_x = x
      line.coord_y = y
      line.coord_z = z
      line.speed   = speed
      line.amount  = amount
      line.command_id = @new_command.id
      line.save
    end
  end

  def save_new_command
    if @new_command != nil
      @new_command.status = 'scheduled'
      @new_command.save
    end
    increment_refresh
  end

  def clear_schedule

    Command.find(:all,:conditions => ["status = ? AND scheduled_time IS NOT NULL",'scheduled']).each do |cmd|
      cmd.delete
    end

    #Command.find(:all,:conditions => ["status = ? ",'scheduled'], :order => 'scheduled_time ASC').last

#Command.find(:all,:conditions => ["status = ? ",'scheduled'], :order => 'scheduled_time ASC').last

#    Command.where(
#      :status => 'scheduled',
#      :scheduled_time.ne => nil
#      ).order_by([:scheduled_time,:asc]).each do |command|
#
#      command.status = 'deleted'
#      command.save
      
#    end
  end

  def clear_crop_schedule(crop_id)
 
    Command.find(:all,:conditions => ["status = ? AND scheduled_time IS NOT NULL AND crop_id = ?",'scheduled',crop_id]).each do |cmd|
      cmd.delete
    end

#   Command.where(
#      :status => 'scheduled',
#      :scheduled_time.ne => nil,
#      :crop_id => crop_id
#      ).order_by([:scheduled_time,:asc]).each do |command|
#
#      command.status = 'deleted'
#      command.save
      
#    end
  end

  def get_command_to_execute

    @last_command_retrieved = Command.find(:all,:conditions => ["status = ? ",'scheduled'], :order => 'scheduled_time ASC').last

#    @last_command_retrieved = Command.where(
#      :status => 'scheduled',
#      :scheduled_time.ne => nil
#      ).order_by([:scheduled_time,:asc]).first

    @last_command_retrieved
  end

  def set_command_to_execute_status(new_status)
    if @last_command_retrieved != nil
      @last_command_retrieved.status = new_status
      @last_command_retrieved.save
    end
  end

  def check_refresh
    r = Refresh.find_or_create_by_name 'FarmBotControllerSchedule'
    @refresh_value_new = (r == nil ? 0 : r.value.to_i)
    return @refresh_value_new != @refresh_value
  end

  def save_refresh
    @refresh_value = @refresh_value_new
  end

  def increment_refresh
    r = Refresh.find_or_create_by_name 'FarmBotControllerSchedule'
    r.value = r.value == nil ? 0 : r.value.to_i + 1
    r.save
  end

end
