require 'bson'
require 'mongo'
require 'mongoid'

# Data classes
# This class is dedicated to retrieving and inserting commands into the schedule
# queue for the farm bot Mongo is used as the database, Mongoid as the
# databasemapper

class Command
  include Mongoid::Document

  embeds_many :commandlines

  field :plant_id
  field :crop_id
  field :scheduled_time
  field :executed_time
  field :status

end

class Commandline
  include Mongoid::Document

  embedded_in :command
  #belongs_to :command

  field :action
  field :coord_x
  field :coord_y
  field :coord_z
  field :speed
  field :amount
end

class Refresh
  include Mongoid::Document

  field :name
  field :value
end

# Access class for the database

class DbAccess

  def initialize
    Mongoid.load!("config/mongo.yml", :development)
    @last_command_retrieved = nil
    @refresh_value = 0
    @refresh_value_new = 0

    @new_command = nil
  end

  def test
    db_connection = Mongo::Connection.new
    db_farmbot = db_connection['farmbot_development']
    db_schedule = db_farmbot['schedule']

    db_connection.database_names.each do |name|
      db = db_connection.db(name)
      db.collections.each do |collection|
        puts "#{name} - #{collection.name}"
      end
    end
  end

  def create_new_command(scheduled_time, crop_id)
    @new_command = Command.new
    @new_command.scheduled_time = scheduled_time
    @new_command.crop_id = crop_id
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
      @new_command.status = 'scheduled'
      @new_command.save
    end
    increment_refresh
  end

  def clear_schedule
    Command.where(
      :status => 'scheduled',
      :scheduled_time.ne => nil
      ).order_by([:scheduled_time,:asc]).each do |command|

      command.status = 'deleted'
      command.save
      
    end
  end

  def clear_crop_schedule(crop_id)
    Command.where(
      :status => 'scheduled',
      :scheduled_time.ne => nil,
      :crop_id => crop_id
      ).order_by([:scheduled_time,:asc]).each do |command|

      command.status = 'deleted'
      command.save
      
    end
  end

  def get_command_to_execute
    @last_command_retrieved = Command.where(
      :status => 'scheduled',
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