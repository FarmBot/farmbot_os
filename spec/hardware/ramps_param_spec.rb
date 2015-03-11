require 'spec_helper'
require './lib/status.rb'
require './lib/database/dbaccess.rb'
require './lib/hardware/gcode/ramps_arduino.rb'
require './lib/hardware/gcode/ramps_param.rb'

describe HardwareInterfaceArduino do

  before do
    $db_write_sync = Mutex.new
    DbAccess.current = DbAccess.new('development')
    DbAccess.current = DbAccess.current
    DbAccess.current.disable_log_to_screen()

    $status = Status.new

    @ramps = HardwareInterfaceArduino.new(true)

    @ramps_param = HardwareInterfaceParam.new
    @ramps_param.ramps_arduino = @ramps

    @ramps.ramps_param = @ramps_param

  end

#  def load_param_values_non_arduino

  it "load param values non arduino" do

    x_per_unit = rand(9999999).to_i
    y_per_unit = rand(9999999).to_i
    z_per_unit = rand(9999999).to_i

    DbAccess.current.write_parameter('MOVEMENT_STEPS_PER_UNIT_X', x_per_unit )
    DbAccess.current.write_parameter('MOVEMENT_STEPS_PER_UNIT_Y', y_per_unit )
    DbAccess.current.write_parameter('MOVEMENT_STEPS_PER_UNIT_Z', z_per_unit )

    @ramps_param.load_config_from_database()
    @ramps_param.load_param_values_non_arduino()

    expect(@ramps_param.axis_x_steps_per_unit).to eq(x_per_unit)
    expect(@ramps_param.axis_y_steps_per_unit).to eq(y_per_unit)
    expect(@ramps_param.axis_z_steps_per_unit).to eq(z_per_unit)

  end

#  def load_config_from_database

  it "load config from database" do

    x_per_unit = rand(9999999).to_i
    name       = 'MOVEMENT_STEPS_PER_UNIT_X'

    DbAccess.current.write_parameter(name, x_per_unit )
    @ramps_param.load_config_from_database()

    x_per_unit_retrieved = 0

    @ramps_param.params.each do |p|
      if p['name'] == name
        x_per_unit_retrieved = p['value_db']
      end
    end

    expect(x_per_unit_retrieved).to eq(x_per_unit)

  end

#  def load_param_names

  it "load param names" do
    @ramps_param.params = []
    @ramps_param.load_param_names()

    expect(@ramps_param.params.count).to eq($arduino_default_params.count)
  end

#  def param_name_add(name, id, default)

  it "param name add" do

    name       = rand(9999999).to_s
    id         = rand(9999999).to_i
    default    = rand(9999999).to_i

    @ramps_param.param_name_add(name, id, default)

    param = nil
    @ramps_param.params.each do |p|
      if p['name'] == name
        param = p
      end
    end

    expect(param['name']).to eq(name)
    expect(param['id']).to eq(id)
    expect(param['default']).to eq(default)

    # repeat again so the part where the param already exists is ran too
    @ramps_param.param_name_add(name, id, default)

  end

#  def get_param_by_name(name)

  it "get param by name" do
    name       = rand(9999999).to_s
    id         = rand(9999999).to_i
    default    = rand(9999999).to_i

    @ramps_param.param_name_add(name, id, default)
    param = @ramps_param.get_param_by_name(name)

    expect(param['name']).to eq(name)
    expect(param['id']).to eq(id)
    expect(param['default']).to eq(default)
  end

#  def get_param_by_id(id)

  it "get param by id" do
    name       = rand(9999999).to_s
    id         = rand(9999999).to_i
    default    = rand(9999999).to_i

    @ramps_param.param_name_add(name, id, default)
    param = @ramps_param.get_param_by_id(id)

    expect(param['name']).to eq(name)
    expect(param['id']).to eq(id)
    expect(param['default']).to eq(default)
  end

#  def get_param(name_or_id, by_name_or_id)

  it "get param (by id)" do
    name       = rand(9999999).to_s
    id         = rand(9999999).to_i
    default    = rand(9999999).to_i

    @ramps_param.param_name_add(name, id, default)
    param = @ramps_param.get_param(id, :by_id)

    expect(param['name']).to eq(name)
    expect(param['id']).to eq(id)
    expect(param['default']).to eq(default)
  end

  it "get param (by name)" do

    name       = rand(9999999).to_s
    id         = rand(9999999).to_i
    default    = rand(9999999).to_i

    @ramps_param.param_name_add(name, id, default)
    param = @ramps_param.get_param(name, :by_name)

    expect(param['name']).to eq(name)
    expect(param['id']).to eq(id)
    expect(param['default']).to eq(default)
  end

#  def save_param_value(name_or_id, by_name_or_id, from_device_or_db, value)

  it "save param value (by id, by device)" do
    name       = rand(9999999).to_s
    id         = rand(9999999).to_i
    default    = rand(9999999).to_i
    value      = rand(9999999).to_i

    @ramps_param.param_name_add(name, id, default)
    @ramps_param.save_param_value(id, :by_id, :from_device, value)
    param = @ramps_param.get_param(id, :by_id)

    expect(param['name']).to eq(name)
    expect(param['id']).to eq(id)
    expect(param['default']).to eq(default)
    expect(param['value_ar']).to eq(value)

  end

  it "save param value (by name, by device)" do
    name       = rand(9999999).to_s
    id         = rand(9999999).to_i
    default    = rand(9999999).to_i
    value      = rand(9999999).to_i

    @ramps_param.param_name_add(name, id, default)
    @ramps_param.save_param_value(name, :by_name, :from_device, value)
    param = @ramps_param.get_param(name, :by_name)

    expect(param['name']).to eq(name)
    expect(param['id']).to eq(id)
    expect(param['default']).to eq(default)
    expect(param['value_ar']).to eq(value)

  end

  it "save param value (by id, by database)" do
    name       = rand(9999999).to_s
    id         = rand(9999999).to_i
    default    = rand(9999999).to_i
    value      = rand(9999999).to_i

    @ramps_param.param_name_add(name, id, default)
    @ramps_param.save_param_value(id, :by_id, :from_db, value)
    param = @ramps_param.get_param(id, :by_id)

    expect(param['name']).to eq(name)
    expect(param['id']).to eq(id)
    expect(param['default']).to eq(default)
    expect(param['value_db']).to eq(value)

  end

  it "save param value (by name, by database)" do
    name       = rand(9999999).to_s
    id         = rand(9999999).to_i
    default    = rand(9999999).to_i
    value      = rand(9999999).to_i

    @ramps_param.param_name_add(name, id, default)
    @ramps_param.save_param_value(name, :by_name, :from_db, value)
    param = @ramps_param.get_param(name, :by_name)

    expect(param['name']).to eq(name)
    expect(param['id']).to eq(id)
    expect(param['default']).to eq(default)
    expect(param['value_db']).to eq(value)

  end

#  def read_parameter_from_device(id)

  it "read parameter from device" do

    id = 1
    value      = rand(9999999).to_i

    @ramps.clean_serial_buffer()
    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = "R21 P#{id} V#{value}\n"
    @ramps_param.read_parameter_from_device(id)

    param = @ramps_param.get_param(id, :by_id)

    expect(param['id']).to eq(id)
    expect(param['value_ar']).to eq(value)
  end

#  def write_parameter_to_device(id, value)

  it "write parameter to device" do

    id         = 1
    default    = rand(9999999).to_i
    value      = rand(9999999).to_i

    @ramps_param.save_param_value(id, :by_id, :from_db, value)

    @ramps.clean_serial_buffer()
    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = "R01\nR02\n"

    @ramps_param.write_parameter_to_device(id, value)

    expect(@ramps.test_serial_write).to eq("F22 P#{id} V#{value}\n")

  end

#  def update_param_version_ar

  it "update parameter version from arduino" do

    id = 0
    value      = rand(9999999).to_i

    @ramps.clean_serial_buffer()
    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = "R21 P#{id} V#{value}\n"
    @ramps_param.update_param_version_ar()

    expect(@ramps_param.param_version_ar).to eq(value)
  end

#  def parameters_different

  it "parameters different false" do

    @ramps_param.params.each do |p|
      p['value_ar'] = p['value_db']
    end

    different = @ramps_param.parameters_different()

    expect(different).to eq(false)
  end

  it "parameters different true" do

    id = 11
    value = rand(9999999).to_i

    @ramps_param.params.each do |p|
      p['value_ar'] = p['value_db']
    end

    @ramps_param.save_param_value(id, :by_id, :from_db, value)

    different = @ramps_param.parameters_different()

    expect(different).to eq(true)
  end

#  def check_and_write_parameter(param)

  it "check and write one parameter, test with similar" do


    name   = 'TESTING'
    id     = 1
    value  = rand(9999999).to_i
    value2 = rand(9999999).to_i

    DbAccess.current.write_parameter(name,value)

    param = @ramps_param.get_param(id, :by_id)
    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = "R21 P#{id} V#{value}\n"

    differences_found = @ramps_param.check_and_write_parameter(param)

    expect(differences_found).to eq(false)
  end

  it "check and write one parameter, test with different" do


    name   = 'TESTING'
    id     = 1
    value  = rand(9999999).to_i
    value2 = rand(9999999).to_i

    DbAccess.current.write_parameter(name,value)

    param = @ramps_param.get_param(id, :by_id)
    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = "R21 P#{id} V#{value2}\n"

    differences_found = @ramps_param.check_and_write_parameter(param)

    expect(differences_found).to eq(true)
    expect(@ramps.test_serial_write).to eq("F22 P#{id} V#{value}\n")
  end

#  def compare_and_write_parameters

  it "compare and write paramters, different" do

    name = 'TESTING'
    id   = 1

    value0  = rand(9999999).to_i
    value1  = rand(9999999).to_i
    value2  = rand(9999999).to_i
    value3  = rand(9999999).to_i
    value4  = rand(9999999).to_i

    DbAccess.current.write_parameter(name,value0)

    @ramps_param.param_version_db = value3
    @ramps_param.param_version_ar = value4

    @ramps_param.params.each do |p|
      p['value_ar'] = p['value_db']
    end

    @ramps_param.params.each do |p|
      if p['id'] == id
        p['value_ar'] = value1
        p['value_db'] = value2
      end
    end

    #@ramps_param.save_param_value(id, :by_id, :from_db, value)
    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = ""

    @ramps_param.compare_and_write_parameters()

    expect(@ramps.test_serial_write).to eq("F22 P#{id} V#{value0}\n")
    expect(@ramps_param.params_in_sync).to eq(false)
  end

  it "compare and write paramters, no difference" do

    name = 'TESTING'
    id   = 1

    value  = rand(9999999).to_i

    @ramps_param.param_version_db = value
    @ramps_param.param_version_ar = value

    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = ""

    @ramps_param.compare_and_write_parameters()

    expect(@ramps.test_serial_write).to eq("")
    expect(@ramps_param.params_in_sync).to eq(true)
  end

  it "compare and write paramters, different version, all parameters identical" do

    name = 'TESTING'
    id   = 1

    value  = rand(9999999).to_i

    @ramps_param.params.each do |p|
        p['value_ar'] = p['value_db']
    end

    @ramps_param.param_version_db = value
    @ramps_param.param_version_ar = value - 1

    DbAccess.current.write_parameter('PARAM_VERSION',@ramps_param.param_version_db)

    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = ""

    @ramps_param.compare_and_write_parameters()

    expect(@ramps.test_serial_write).to eq("F22 P0 V#{value}\n")
    expect(@ramps_param.params_in_sync).to eq(true)
  end


#  def check_parameters

  it "check parameter, no difference" do

    name = 'TESTING'
    id   = 1

    db_version  = rand(9999999).to_i

    DbAccess.current.write_parameter('PARAM_VERSION',db_version)

    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = "R21 P0 V#{db_version}\n"

    @ramps_param.check_parameters()

    expect(@ramps_param.params_in_sync).to eq(true)

  end

  it "check parameter, different" do

    name = 'TESTING'
    id   = 1

    db_version  = rand(9999999).to_i
    ar_version  = rand(9999999).to_i

    value0  = rand(9999999).to_i
    value1  = rand(9999999).to_i
    value2  = rand(9999999).to_i

    DbAccess.current.write_parameter(name,value0)
    DbAccess.current.write_parameter('PARAM_VERSION',db_version)

    @ramps.test_serial_write = ""
    @ramps.test_serial_read  = "R21 P0 V#{ar_version}\n"

    # make sure all parameters in device and database are equal
    @ramps_param.params.each do |p|
      p['value_ar'] = p['value_db']
    end

    # then only change one parameter
    @ramps_param.params.each do |p|
      if p['id'] == id
        p['value_ar'] = value1
        p['value_db'] = value2
      end
    end

    @ramps_param.check_parameters()

    expect(@ramps_param.params_in_sync).to eq(false)
    expect(@ramps.test_serial_write).to eq("F22 P#{id} V#{value0}\n")

  end

end

