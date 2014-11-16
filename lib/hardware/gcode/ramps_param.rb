## HARDWARE INTERFACE
## ******************

# Communicate with the arduino using a serial interface
# All information is exchanged using a variation of g-code
# Parameters are stored in the database

#require 'serialport'

class HardwareInterfaceParam

   attr_reader :param_version_db,      :param_version_ar,      :params_in_sync, :params
   attr_reader :axis_x_steps_per_unit, :axis_y_steps_per_unit, :axis_z_steps_per_unit

  # initialize the interface
  #
  def initialize

    @status_debug_msg = $status_debug_msg
    #@status_debug_msg = false
    #@status_debug_msg = true

    # init database and parameters

    @bot_dbaccess          = $bot_dbaccess
    @params                = Array.new
    @external_info         = ""
    @param_version_db      = 0
    @param_version_ar      = 0
    @params_in_sync        = false

    @axis_x_steps_per_unit = 1
    @axis_y_steps_per_unit = 1
    @axis_z_steps_per_unit = 1

    load_param_names()
    load_config_from_database()

    load_param_values_non_arduino()

  end

  ## DATABASE AND SETTINGS HANDLING
  ## ******************************

  # load non-arduino parameters
  #
  def load_param_values_non_arduino

    p = get_param_by_name('MOVEMENT_STEPS_PER_UNIT_X')
    @axis_x_steps_per_unit = p['value_db']

    p = get_param_by_name('MOVEMENT_STEPS_PER_UNIT_Y')
    @axis_y_steps_per_unit = p['value_db']

    p = get_param_by_name('MOVEMENT_STEPS_PER_UNIT_Z')
    @axis_z_steps_per_unit = p['value_db']

  end

  # load the settings for the hardware
  # these are the timeouts and distance settings mainly
  #
  def load_config_from_database
    @params.each do |p|
       p['value_db'] = @bot_dbaccess.read_parameter_with_default(p['name'], p['default'])
    end
  end

  # load the id's of the arduino parameters
  #
  def load_param_names
    param_name_add('PARAM_VERSION'                ,  0,    0)
    param_name_add('MOVEMENT_TIMEOUT_X'           , 11,   15)
    param_name_add('MOVEMENT_TIMEOUT_Y'           , 12,   15)
    param_name_add('MOVEMENT_TIMEOUT_Z'           , 13,   15)
    param_name_add('MOVEMENT_INVERT_ENDPOINTS_X'  , 21,    0)
    param_name_add('MOVEMENT_INVERT_ENDPOINTS_Y'  , 22,    0)
    param_name_add('MOVEMENT_INVERT_ENDPOINTS_Z'  , 23,    0)
    param_name_add('MOVEMENT_INVERT_MOTOR_X'      , 31,    0)
    param_name_add('MOVEMENT_INVERT_MOTOR_Y'      , 32,    0)
    param_name_add('MOVEMENT_INVERT_MOTOR_Z'      , 33,    0)
    param_name_add('MOVEMENT_STEPS_ACC_DEC_X'     , 41,  100)
    param_name_add('MOVEMENT_STEPS_ACC_DEC_Y'     , 42,  100)
    param_name_add('MOVEMENT_STEPS_ACC_DEC_Z'     , 43,  100)
    param_name_add('MOVEMENT_HOME_UP_X'           , 51,    0)
    param_name_add('MOVEMENT_HOME_UP_Y'           , 52,    0)
    param_name_add('MOVEMENT_HOME_UP_Z'           , 53,    0)
    param_name_add('MOVEMENT_MIN_SPD_X'           , 61,  200)
    param_name_add('MOVEMENT_MIN_SPD_Y'           , 62,  200)
    param_name_add('MOVEMENT_MIN_SPD_Z'           , 63,  200)
    param_name_add('MOVEMENT_MAX_SPD_X'           , 71, 1000)
    param_name_add('MOVEMENT_MAX_SPD_Y'           , 72, 1000)
    param_name_add('MOVEMENT_MAX_SPD_Z'           , 73, 1000)
    param_name_add('MOVEMENT_LENGTH_X'            ,801, 1000)
    param_name_add('MOVEMENT_LENGTH_Y'            ,802, 1000)
    param_name_add('MOVEMENT_LENGTH_Z'            ,803, 1000)
    param_name_add('MOVEMENT_STEPS_PER_UNIT_X'    ,901,    5)
    param_name_add('MOVEMENT_STEPS_PER_UNIT_Y'    ,902,    5)
    param_name_add('MOVEMENT_STEPS_PER_UNIT_Z'    ,903,    5)

  end

  # add a parameter to the param list
  #
  def param_name_add(name, id, default)
    param = Hash.new
    param['name']     = name
    param['id']       = id
    param['value_db'] = 0
    param['value_ar'] = 0
    param['default']  = default
    @params << param
  end

  # get the parameter object by name
  #
  def get_param_by_name(name) 
    param = nil
    @params.each do |p|
      if p['name'] == name
        param = p
      end
    end
    return param
  end

  # get the parameter object by id
  #
  def get_param_by_id(id)
    param = nil
    @params.each do |p|
      if p['id'] == id
        param = p
      end
    end
    return param
  end

  # get parameter object by name or id
  #
  def get_param(name_or_id, by_name_or_id)
    param = nil
    @params.each do |p|
      if (by_name_or_id == :by_id   and p['id']   == name_or_id)
        param = p
      end
      if (by_name_or_id == :by_name and p['name'] == name_or_id)
        param = p
      end
    end
    return param
  end

  # read parameter value from memory
  #
  def get_param_value_by_id(name_or_id, by_name_or_id, from_device_or_db, default_value)
    value = default_value
    
    param = get_param(id, by_name_or_id)
    if param != nil and from_device_or_db == :from_device
      value =  param['value_ar']
    end
    if param != nil and from_device_or_db == :from_db
      value =  param['value_db']
    end

  end

  #def get_param_value_by_name(name)
  #end

  # save parameter value to the database
  #
  def save_param_value(name_or_id, by_name_or_id, from_device_or_db, value)

    param = get_param(name_or_id, by_name_or_id)

    if param != nil and from_device_or_db == :from_device
      param['value_ar'] = value
    end
    if param != nil and from_device_or_db == :from_db
      param['value_db'] = value
    end

    @bot_dbaccess.write_parameter(param['name'],value)
  end

  # save a pin measurement
  #
  def save_pin_value(pin_id, pin_val)
    @bot_dbaccess.write_measuements(pin_val, @external_info)
  end

end
