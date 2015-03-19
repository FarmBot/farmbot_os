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

  it "fill parameter values int"  do
    param_name  = 'TEST_VALUE_6'
    param_value = 543

    param = Parameter.find_or_create_by(name: param_name)
    @db.fill_parameter_if_fixnum(param, param_value)    
    return_val = param.valueint

    expect(return_val).to eq(param_value)    
  end

  it "fill parameter values float"  do
    param_name  = 'TEST_VALUE_6'
    param_value = 54.32

    param = Parameter.find_or_create_by(name: param_name)
    @db.fill_parameter_if_float(param, param_value)    
    return_val = param.valuefloat

    expect(return_val).to eq(param_value)    
  end

  it "fill parameter values string"  do
    param_name  = 'TEST_VALUE_6'
    param_value = "UVW"

    param = Parameter.find_or_create_by(name: param_name)
    @db.fill_parameter_if_string(param, param_value)    
    return_val = param.valuestring

    expect(return_val).to eq(param_value)    
  end

  it "fill parameter values bool"  do
    param_name  = 'TEST_VALUE_6'
    param_value = true

    param = Parameter.find_or_create_by(name: param_name)
    @db.fill_parameter_if_bool(param, param_value)    
    return_val = param.valuebool

    expect(return_val).to eq(param_value)    
  end

  it "fill parameter values 2 int"  do
    param_name  = 'TEST_VALUE_6'
    param_value = 543

    param = Parameter.find_or_create_by(name: param_name)
    @db.fill_parameter_values(param, param_value)    
    return_val = param.valueint

    expect(return_val).to eq(param_value)    
  end

  it "fill parameter values 2 float"  do
    param_name  = 'TEST_VALUE_6'
    param_value = 54.32

    param = Parameter.find_or_create_by(name: param_name)
    @db.fill_parameter_values(param, param_value)    
    return_val = param.valuefloat

    expect(return_val).to eq(param_value)    
  end

  it "fill parameter values 2 string"  do
    param_name  = 'TEST_VALUE_6'
    param_value = "UVW"

    param = Parameter.find_or_create_by(name: param_name)
    @db.fill_parameter_values(param, param_value)    
    return_val = param.valuestring

    expect(return_val).to eq(param_value)    
  end

  it "fill parameter values 2 bool"  do
    param_name  = 'TEST_VALUE_6'
    param_value = true

    param = Parameter.find_or_create_by(name: param_name)
    @db.fill_parameter_values(param, param_value)    
    return_val = param.valuebool

    expect(return_val).to eq(param_value)    
  end

  it "read parameter list" do

    # write a parameter 
    param_name  = 'TEST_VALUE_LIST_1'
    param_value = 'ABC'
    return_val  = ''

    @db.write_parameter(param_name, param_value)

    # get the list
    list = @db.read_parameter_list()

    list.each do |param|
      if param['name'] == param_name 
        return_val = param['value']
      end
    end

    expect(return_val).to eq(param_value)
  end


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

  it "read parameter" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE_5'
    param_value = 321
    @db.write_parameter(param_name,  param_value)

    # read it back to see if it maches
    return_val = @db.read_parameter(param_name)

    expect(return_val).to eq(param_value)
  end

  it "read parameter with default" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE_0'
    param_value = 432

    @db.write_parameter_with_type(param_name, 1, param_value)

    return_val = @db.read_parameter_with_default(param_name, param_value)

    expect(return_val).to eq(param_value)
  end

  it "read parameter with default, value is nil" do
    # write a parameter of type int
    param_name  = 'TEST_VALUE_0'
    param_value = 0

    param = Parameter.find_or_create_by(name: param_name)
    param.valuetype = 1

    param.valueint    = nil;
    param.valuefloat  = nil;
    param.valuestring = nil;
    param.valuebool   = nil;

    $db_write_sync.synchronize do
      param.save
    end

    return_val = @db.read_parameter_with_default(param_name, param_value)

    expect(return_val).to eq(param_value)
  end

end
