require 'bson'
require 'mongo'
require 'mongoid'

require './app/models/command.rb'

# This class is dedicated to retrieving and inserting commands into the command 
# queue for the farm bot
class CommandQueue

  def initialize
    Mongoid.load!("config/mongo.yml", :development)
    @last_command_retrieved = nil
    @refresh_value = 0
    @refresh_value_new = 0

    @new_command = nil
  end

  def create_new_command(scheduled_time)
    @new_command = Command.new
    @new_command.scheduled_time = scheduled_time
  end

  def add_command_line(action, x = 0, y = 0, z = 0, speed = 0, amount = 0)
    if @new_command != nil
      line = Commandline.new
      line.action = action
      line.coord_x = x
      line.coord_y = y
      line.coord_z = z
      line.speed   = speed
      line.amount  = amount
      if @new_command.commandlines == nil
        @new_command.commandlines = [ line ]
      else
        @new_command.commandlines << line
      end
    end
  end

  def save_new_command
    if @new_command != nil
      @new_command.status = 'test'
      @new_command.save
    end
    increment_refresh
  end

  def get_command_to_execute
    @last_command_retrieved = Command.where(
      :status => 'test',
      :scheduled_time.ne => nil
      ).order_by([:scheduled_time,:asc]).first
    @last_command_retrieved
  end

  def set_command_to_execute_status(new_status)
    if @last_command_retrieved != nil
      @last_command_retrieved.status = new_status
      @last_command_retrieved.save
    end
  end

  def check_refresh
    r = Refresh.where(:name => 'FarmBotControllerSchedule').first_or_initialize
    @refresh_value_new = r.value.to_i
    return @refresh_value_new != @refresh_value
  end

  def save_refresh
    @refresh_value = @refresh_value_new
  end

  def increment_refresh
    r = Refresh.where(:name => 'FarmBotControllerSchedule').first_or_initialize
    r.value = r.value.to_i + 1
    r.save
  end

end