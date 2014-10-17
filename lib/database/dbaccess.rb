require 'bson'
require 'sqlite3'
require 'active_record'

require './app/models/command.rb'
require './app/models/command_line.rb'
require './app/models/refresh.rb'
require './app/models/log.rb'
require './app/models/parameter.rb'
require './app/models/measurement.rb'

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

  ## parameters

  # increment param version
  #
  def increment_parameters_version
    $db_write_sync.synchronize do
      param = Parameter.find_or_create_by(name: 'PARAM_VERSION')
      param.valuetype = 1 if param.valuetype != 1
      param.valueint = 0 if param.valueint == nil
      param.valueint = param.valueint + 1
      param.save
    end
  end

  # write a parameter
  #
  def write_parameter(name, value)
    param = Parameter.find_or_create_by(name: name)
    
    if value.class.to_s == "Fixnum"
      param.valueint    = value.to_i
      param.valuetype   = 1
    end
    if value.class.to_s == "Float"
      param.valuefloat  = value.to_f
      param.valuetype   = 2
    end
    if value.class.to_s == "String"
      param.valuestring = value.to_s
      param.valuetype   = 3
    end
    if value.class.to_s == "TrueClass" or value.class.to_s == "FalseClass"
      param.valuebool   = value
      param.valuetype   = 4
    end

    $db_write_sync.synchronize do
      param.save
    end
    increment_parameters_version()

  end

  # write a parameter with type provided
  #
  def write_parameter_with_type(name, type, value)

    param = Parameter.find_or_create_by(name: name)
    param.valuetype = type

    param.valueint    = type == 1 ? value.to_i : nil;
    param.valuefloat  = type == 2 ? value.to_f : nil
    param.valuestring = type == 3 ? value.to_s : nil
    param.valuebool   = type == 4 ? value      : nil

    $db_write_sync.synchronize do
      param.save
    end
    increment_parameters_version

  end


  # read parameter list
  #
  def read_parameter_list()
    params = Parameter.find(:all)    
    param_list = Array.new

    params.each do |param|
      value = param.valueint    if param.valuetype == 1
      value = param.valuefloat  if param.valuetype == 2
      value = param.valuestring if param.valuetype == 3
      value = param.valuebool   if param.valuetype == 4
      item = 
      {
        'name'  => param.name,
        'type'  => param.valuetype,
        'value' => value
      }
      param_list << item
    end

    param_list
  end

  # read parameter
  #
  def read_parameter(name)
    param = Parameter.find_or_create_by(name: name)

    type = param.valuetype
    value = param.valueint    if type == 1
    value = param.valuefloat  if type == 2
    value = param.valuestring if type == 3
    value = param.valuebool   if type == 4
    value
  end

  # read parameter
  #
  def read_parameter_with_default(name, default_value)

    value = read_parameter(name)

    if value == nil
      value = default_value
      write_parameter(name, value)
    end

    value
  end

  ## measurements

  # write a single measurement
  #
  def write_measuements(value, external_info)
    meas               = Measurement.new
    meas.value         = value
    meas.external_info = external_info
    meas.save
  end

  # read measurement list
  #
  def read_measurement_list()
    measurements = Measurement.all
    measurements_list = Array.new

    measurements.each do |meas|
      item =
      {
        'id'         => meas.measurement_id,
        'ext_info'   => meas.external_info,
        'timestamp'  => meas.created_at,
        'value'      => meas.value
      }
      measurements_list << item
    end

    measurements_list
  end

  # delete a measurement from the database
  #
  def delete_measurement(id)
    if Measurement.exists?(id)
      meas = Measurement.where("measurement_id = (?)", id).first
      meas.delete
    end
  end

  ## logs

  # write a line to the log
  #
  def write_to_log(module_id,text)
    log           = Log.new
    log.text      = text
    log.module_id = module_id
    log.save

    # clean up old logs
    $db_write_sync.synchronize do
      Log.where("created_at < (?)", 2.days.ago).find_each do |log|
        log.delete
      end
    end
  end


  # read all logs from the log file
  #
  def read_logs_all()
    logs = Log.find(:all, :order => 'created_at asc')
  end

  # read from the log file
  #
  def retrieve_log(module_id, nr_of_lines)
    logs = Log.find(:all, :conditions => [ "module_id = (?)", module_id ], :order => 'created_at asc', :limit => nr_of_lines)
  end

  ## commands

  def create_new_command(scheduled_time, crop_id)
    @new_command = Command.new
    @new_command.scheduled_time = scheduled_time
    @new_command.crop_id = crop_id
    @new_command.status = 'creating'
    @new_command.save
  end

  def add_command_line(action, x = 0, y = 0, z = 0, speed = 0, amount = 0, pin_nr = 0, value1 = 0, value2 = 0, mode = 0, time = 0, external_info = "")
    if @new_command != nil
      line = CommandLine.new
      line.action = action
      line.coord_x       = x
      line.coord_y       = y
      line.coord_z       = z
      line.speed         = speed
      line.amount        = amount
      line.command_id    = @new_command.id
      line.pin_nr        = pin_nr
      line.pin_value_1   = value1
      line.pin_value_2   = value2
      line.pin_mode      = mode
      line.pin_time      = time
      line.external_info = external_info
      $db_write_sync.synchronize do
        line.save
      end
    end
  end

  def save_new_command
    if @new_command != nil
      @new_command.status = 'scheduled'
      $db_write_sync.synchronize do
        @new_command.save
      end
    end
    increment_refresh
  end

  def clear_schedule
    $db_write_sync.synchronize do
      Command.where("status = ? AND scheduled_time IS NOT NULL",'scheduled').find_each do |cmd|
        cmd.delete
      end
    end
  end

  def clear_crop_schedule(crop_id)
    $db_write_sync.synchronize do
      Command.where("status = ? AND scheduled_time IS NOT NULL AND crop_id = ?",'scheduled',crop_id).find_each do |cmd|
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

  ## refreshes

  def check_refresh
    r = Refresh.find_or_create_by(name: 'FarmBotControllerSchedule')
    @refresh_value_new = (r == nil ? 0 : r.value.to_i)
    return @refresh_value_new != @refresh_value
  end

  def save_refresh
    @refresh_value = @refresh_value_new
  end

  def increment_refresh
    r = Refresh.find_or_create_by(name: 'FarmBotControllerSchedule')
    r.value = r.value == nil ? 0 : r.value.to_i + 1
    $db_write_sync.synchronize do
      r.save
    end
  end

end
