require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

  ## parameters

  it "write parameter integer" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE'
    param_value = 12345
    @db.write_parameter(param_name, param_value)

    # read it back to see if it maches
    param = Parameter.find_or_create_by(name: param_name)
    return_val = param.valueint

    expect(return_val).to eq(param_value)
  end

  it "write parameter float" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE'
    param_value = 12.345
    @db.write_parameter(param_name, param_value)

    # read it back to see if it maches
    param = Parameter.find_or_create_by(name: param_name)
    return_val = param.valuefloat

    expect(return_val).to eq(param_value)
  end

  it "write parameter string" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE'
    param_value = 'XYZ'
    @db.write_parameter(param_name, param_value)

    # read it back to see if it maches
    param = Parameter.find_or_create_by(name: param_name)
    return_val = param.valuestring

    expect(return_val).to eq(param_value)
  end

  it "write parameter bool" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE'
    param_value = true
    @db.write_parameter(param_name, param_value)

    # read it back to see if it maches
    param = Parameter.find_or_create_by(name: param_name)
    return_val = param.valuebool

    expect(return_val).to eq(param_value)
  end

  it "increments param version" do
    param_name = 'PARAM_VERSION'
    @db.write_parameter(param_name, 1)
    @db.increment_parameters_version
    return_val = @db.read_parameter(param_name)

    expect(return_val).to eq(2)
  end

  # write parameter with type

  it "write parameter integer" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE_2'
    param_value = 45678
    @db.write_parameter_with_type(param_name, 1, param_value)

    # read it back to see if it maches
    param = Parameter.find_or_create_by(name: param_name)
    return_val = param.valueint

    expect(return_val).to eq(param_value)
  end

  it "write parameter float" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE_2'
    param_value = 34.567
    @db.write_parameter_with_type(param_name, 2, param_value)

    # read it back to see if it maches
    param = Parameter.find_or_create_by(name: param_name)
    return_val = param.valuefloat

    expect(return_val).to eq(param_value)
  end

  it "write parameter string" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE_2'
    param_value = 'ABC'
    @db.write_parameter_with_type(param_name, 3, param_value)

    # read it back to see if it maches
    param = Parameter.find_or_create_by(name: param_name)
    return_val = param.valuestring

    expect(return_val).to eq(param_value)
  end

  it "write parameter bool" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE_2'
    param_value = false
    @db.write_parameter_with_type(param_name, 4, param_value)

    # read it back to see if it maches
    param = Parameter.find_or_create_by(name: param_name)
    return_val = param.valuebool

    expect(return_val).to eq(param_value)
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

#  def read_parameter_list()
#    @parameters.read_parameter_list()
#  end

  it "get value from parameter int" do
    param_name  = 'TEST_VALUE_4'
    param_value = 7890

    param = Parameter.find_or_create_by(name: param_name)
    param.valuetype = 1
    param.valueint  = param_value

    return_val = @db.get_value_from_param(param)

    expect(return_val).to eq(param_value)
  end

  it "get value from parameter float" do
    param_name  = 'TEST_VALUE_4'
    param_value = 78.90

    param = Parameter.find_or_create_by(name: param_name)
    param.valuetype  = 2
    param.valuefloat = param_value

    return_val = @db.get_value_from_param(param)

    expect(return_val).to eq(param_value)
  end

  it "get value from parameter string" do
    param_name  = 'TEST_VALUE_4'
    param_value = 'DEF'

    param = Parameter.find_or_create_by(name: param_name)
    param.valuetype   = 3
    param.valuestring = param_value

    return_val = @db.get_value_from_param(param)

    expect(return_val).to eq(param_value)
  end

  it "get value from parameter bool" do
    param_name  = 'TEST_VALUE_4'
    param_value = true

    param = Parameter.find_or_create_by(name: param_name)
    param.valuetype = 4
    param.valuebool = param_value

    return_val = @db.get_value_from_param(param)

    expect(return_val).to eq(param_value)
  end


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
