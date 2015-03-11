## HARDWARE INTERFACE
## ******************

# Communicate with the arduino using a serial interface
# All information is exchanged using a variation of g-code
# Parameters are stored in the database

#require 'serialport'

require_relative 'ramps_param_defaults.rb'

class HardwareInterfaceParam

  attr_accessor :params
  attr_accessor :param_version_db,      :param_version_ar,      :params_in_sync
  attr_reader   :axis_x_steps_per_unit, :axis_y_steps_per_unit, :axis_z_steps_per_unit
  attr_accessor :ramps_arduino,         :ramps_main


  # initialize the interface
  #
  def initialize

    @status_debug_msg = $status_debug_msg
    #@status_debug_msg = false
    #@status_debug_msg = true

    # init database and parameters

    @bot_dbaccess          = DbAccess.current
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

  #def load_param_defaults
  #  @param_json = ''
  #end

  # load the id's of the arduino parameters
  #
  def load_param_names
    $arduino_default_params.each do |p|
       param_name_add(p[:name], p[:id], p[:value])
    end
  end

  # add a parameter to the param list
  #
  def param_name_add(name, id, default)
    found = false
    @params.each do |p|
      if p['name'] == name
        found = true
      end
    end

    if found == false
      param = Hash.new
      param['name']     = name
      param['id']       = id
      param['value_db'] = 0
      param['value_ar'] = 0
      param['default']  = default
      @params << param
    end
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

  #def get_param_value_by_id(name_or_id, by_name_or_id, from_device_or_db, default_value)
  #  value = default_value
  #
  #  param = get_param(id, by_name_or_id)
  #  if param != nil and from_device_or_db == :from_device
  #    value =  param['value_ar']
  #  end
  #  if param != nil and from_device_or_db == :from_db
  #    value =  param['value_db']
  #  end
  #
  #end

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


  # check to see of parameters in arduino are up to date
  #
  def check_parameters
    update_param_version_ar()
    @param_version_db = @bot_dbaccess.read_parameter_with_default('PARAM_VERSION', 0)
    compare_and_write_parameters()
  end

  def update_param_version_ar
    # read the parameter version in the database and in the device
    read_parameter_from_device(0)
    params.each do |p|
      if p['id'] == 0
        @param_version_ar = p['value_ar']
      end
    end
  end

  def compare_and_write_parameters
    # if the parameters in the device is different from the database parameter version
    # read and compare each parameter and write to device is different

    if @param_version_db != @param_version_ar

      load_param_values_non_arduino()

      if !parameters_different()
        @params_in_sync = true
        write_parameter_to_device(0, @param_version_db)
      else
        @params_in_sync = false
      end
    else
      @params_in_sync = true
    end
  end

  def parameters_different
    differences_found_total = false
    params.each do |p|
      if p['id'] != 0
        difference = check_and_write_parameter(p)
        if difference then
          @params_in_sync = false
          differences_found_total = true
        end
      end
    end
    differences_found_total
  end

  # synchronise a parameter value
  #
  def check_and_write_parameter(param)

     # read value from device and database
     read_parameter_from_device(param['id'])
     param['value_db'] = @bot_dbaccess.read_parameter_with_default(param['name'], 0)

     differences_found = false

     # if the parameter value between device and database is different, write value to device
     if param['value_db'] != param ['value_ar']
       differences_found = true
       write_parameter_to_device(param['id'],param['value_db'])
     end

    return differences_found

  end

  # read a parameter from arduino
  #
  def read_parameter_from_device(id)
    @ramps_arduino.execute_command("F21 P#{id}", false, false)
  end

  # write a parameter value to arduino
  #
  def write_parameter_to_device(id, value)
    @ramps_arduino.execute_command("F22 P#{id} V#{value}", false, false)
  end

end
