require 'bson'
require 'sqlite3'
require 'active_record'

require './app/models/parameter.rb'
require './app/models/measurement.rb'

# retrieving and inserting commands into the schedule queue for the farm bot
# using sqlite

# Access class for the database

class DbAccessParameters

  attr_writer :dbaccess

  def initialize
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
    
    fill_parameter_values(param, value)

    $db_write_sync.synchronize do
      param.save
    end
    increment_parameters_version()

  end

  def fill_parameter_values(  param, value)
    fill_parameter_if_fixnum( param, value)
    fill_parameter_if_float(  param, value)
    fill_parameter_if_string( param, value)
    fill_parameter_if_bool(   param, value)
  end

  def fill_parameter_if_fixnum(param, value)
    if value.class.to_s == "Fixnum"
      param.valueint    = value.to_i
      param.valuetype   = 1
    end
  end

  def fill_parameter_if_float(param, value)
    if value.class.to_s == "Float"
      param.valuefloat  = value.to_f
      param.valuetype   = 2
    end
  end

  def fill_parameter_if_string(param, value)
    if value.class.to_s == "String"
      param.valuestring = value.to_s
      param.valuetype   = 3
    end
  end

  def fill_parameter_if_bool(param, value)
    if value.class.to_s == "TrueClass" or value.class.to_s == "FalseClass"
      param.valuebool   = value
      param.valuetype   = 4
    end
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
      #value = get_value_from_param(param)
      item = 
      {
        'name'  => param.name,
        'type'  => param.valuetype,
        'value' => get_value_from_param(param)
      }
      param_list << item
    end

    param_list
  end

  def get_value_from_param(param)
    value = param.valueint    if param.valuetype == 1
    value = param.valuefloat  if param.valuetype == 2
    value = param.valuestring if param.valuetype == 3
    value = param.valuebool   if param.valuetype == 4
    return value
  end

  # read parameter
  #
  def read_parameter(name)
    param = Parameter.find_or_create_by(name: name)
    get_value_from_param(param)
    #type = param.valuetype
    #value = param.valueint    if type == 1
    #value = param.valuefloat  if type == 2
    #value = param.valuestring if type == 3
    #value = param.valuebool   if type == 4
    #value
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

end
