require 'bson'
require 'sqlite3'
require 'active_record'

require_relative 'dbaccess_commands.rb'
require_relative 'dbaccess_refreshes.rb'
require_relative 'dbaccess_logs.rb'
require_relative 'dbaccess_parameters.rb'
require_relative 'dbaccess_measurements.rb'

# retrieving and inserting commands into the schedule queue for the farm bot
# using sqlite

# Access class for the database

class DbAccess

  def initialize(environemnt)
    config = YAML::load(File.open('./config/database.yml'))
    ActiveRecord::Base.establish_connection(config[environment])

    @commands     = DbAccessCommands.new
    @refreshes    = DbAccessRefreshes.new
    @logs         = DbAccessLogs.new
    @parameters   = DbAccessParameters.new
    @measurements = DbAccessMeasurements.new

  end

  ## parameters

  def increment_parameters_version
    @parameters.increment_parameters_version
  end

  def write_parameter(name, value)
    @parameters.write_parameter(name, value)
  end

  def fill_parameter_values(  param, value)
    @parameters.fill_parameter_values(  param, value)
  end

  def fill_parameter_if_fixnum(param, value)
    @parameters.fill_parameter_if_fixnum(param, value)
  end

  def fill_parameter_if_float(param, value)
    @parameters.fill_parameter_if_float(param, value)
  end

  def fill_parameter_if_string(param, value)
    @parameters.fill_parameter_if_string(param, value)
  end

  def fill_parameter_if_bool(param, value)
    @parameters.fill_parameter_if_bool(param, value)
  end

  def write_parameter_with_type(name, type, value)
    @parameters.write_parameter_with_type(name, type, value)
  end

  def read_parameter_list()
    @parameters.read_parameter_list()
  end

  def get_value_from_param(param)
    @parameters.get_value_from_param(param)
  end

  def read_parameter(name)
    @parameters.read_parameter(name)
  end

  def read_parameter_with_default(name, default_value)
    @parameters.read_parameter_with_default(name, default_value)
  end

  ## measurements

  def write_measurements(value, external_info)
    @measurements.write_measurements(value, external_info)
  end

  def read_measurement_list()
    @measurements.read_measurement_list()
  end

  def delete_measurement(id)
    @measurements.delete_measurement(id)
  end

  ## logs

  def write_to_log(module_id,text)
    @logs.write_to_log(module_id,text)
  end

  def read_logs_all()
    @logs.read_logs_all()
  end

  def retrieve_log(module_id, nr_of_lines)
    @logs.retrieve_log(module_id, nr_of_lines)
  end

  ## commands

  def create_new_command(scheduled_time, crop_id)
    @commands.create_new_command(scheduled_time, crop_id)
  end

  def add_command_line(action, x = 0, y = 0, z = 0, speed = 0, amount = 0, pin_nr = 0, value1 = 0, value2 = 0, mode = 0, time = 0, external_info = "")
    @commands.add_command_line(action, x, y, z, speed, amount, pin_nr, value1, value2, mode, time, external_info)
  end

  def fill_in_command_line_coordinates(line, action, x, y, z, speed)
    @commands.fill_in_command_line_coordinates(line, action, x, y, z, speed)
  end

  def fill_in_command_line_pins(line, pin_nr, value1, value2, mode, time)
    @commands.fill_in_command_line_pins(line, pin_nr, value1, value2, mode, time)
  end

  def fill_in_command_line_extra(line, amount = 0, external_info = "")
    @commands.fill_in_command_line_extra(line, amount = 0, external_info = "")
  end

  def save_new_command
    @commands.save_new_command
    @refreshes.increment_refresh
  end

  def clear_schedule
    @commands.clear_schedule
  end

  def clear_crop_schedule(crop_id)
    @commands.clear_crop_schedule(crop_id)
  end

  def get_command_to_execute
    @commands.get_command_to_execute
  end

  def set_command_to_execute_status(new_status)
    @commands.set_command_to_execute_status(new_status)
  end

  ## refreshes

  def check_refresh
    @refreshes.check_refresh
  end

  def save_refresh
    @refresh_value = @refresh_value_new
  end

  def increment_refresh
    @refreshes.increment_refresh
  end

end
