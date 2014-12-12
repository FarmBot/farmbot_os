require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

#  if "read parameter int" do
#    
#  end

  it "write parameter int" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE'
    param_value = 12345
    @db.write_parameter(param_name, param_value)

    # read it back to see if it maches
    param = Parameter.find_or_create_by(name: param_name)
    return_val = param.valueint

    expect(return_val).to eq(param_value)
  end



  it "increments param version" do
    param_name = 'PARAM_VERSION'
    @db.write_parameter(param_name, 1)
    @db.increment_parameters_version
    return_val = @db.read_parameter(param_name)

    expect(return_val).to eq(2)
  end




#  def fill_parameter_values(param, value)
#    @parameters.fill_parameter_values(param, value)
#  end

#  def fill_parameter_if_fixnum(param, value)
#    @parameters.fill_parameter_if_fixnum(param, value)
#  end

#  def fill_parameter_if_float(param, value)
#    @parameters.fill_parameter_if_float(param, value)
#  end

#  def fill_parameter_if_string(param, value)
#    @parameters.fill_parameter_if_string(param, value)
#  end

#  def fill_parameter_if_bool(param, value)
#    @parameters.fill_parameter_if_bool(param, value)
#  end

#  def write_parameter_with_type(name, type, value)
#    @parameters.write_parameter_with_type(name, type, value)
#  end

#  def read_parameter_list()
#    @parameters.read_parameter_list()
#  end

#  def get_value_from_param(param)
#    @parameters.get_value_from_param(param)
#  end

#  def read_parameter(name)
#    @parameters.read_parameter(name)
#  end

#  def read_parameter_with_default(name, default_value)
#    @parameters.read_parameter_with_default(name, default_value)
#  end

  ## measurements

#  def write_measurements(value, external_info)
#    @measurements.write_measurements(value, external_info)
#  end

#  def read_measurement_list()
#    @measurements.read_measurement_list()
#  end

#  def delete_measurement(id)
#    @measurements.delete_measurement(id)
#  end

  ## logs

#  def write_to_log(module_id,text)
#    @logs.write_to_log(module_id,text)
#  end

#  def read_logs_all()
#    @logs.read_logs_all()
#  end

#  def retrieve_log(module_id, nr_of_lines)
#    @logs.retrieve_log(module_id, nr_of_lines)
#  end

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

  ## refreshes

#  def check_refresh
#    @refreshes.check_refresh
#  end

#  def save_refresh
#    @refresh_value = @refresh_value_new
#  end

#  def increment_refresh
#    @refreshes.increment_refresh
#  end



end
