## HARDWARE INTERFACE
## ******************

# Communicate with the arduino using a serial interface
# All information is exchanged using a variation of g-code
# Parameters are stored in the database

#require 'serialport'

require_relative 'ramps_arduino.rb'
require_relative 'ramps_param.rb'

class HardwareInterface

  attr_reader :ramps_param, :ramps_main

  # initialize the interface
  #
  def initialize

    @bot_dbaccess = $bot_dbaccess


    # create the sub processing objects
    @ramps_param   = HardwareInterfaceParam.new
    @ramps_arduino = HardwareInterfaceArduino.new
    @ramps_arduino.ramps_param = @ramps_param
    @ramps_arduino.ramps_main  = self

    @external_info = ""

  end

  ## INTERFACE FUNCTIONS
  ## *******************

  ## control additional I/O (servo, pins, water)

  # move a servo
  #
  def servo_std_move(pin, value)
    @ramps_arduino.execute_command("F61 P#{pin} V#{value}", false, @status_debug_msg)
  end

  # set standard pin value
  #
  def pin_std_set_value(pin, value, mode)
    @ramps_arduino.execute_command("F41 P#{pin} V#{value} M#{mode}", false, @status_debug_msg)
  end

  # read standard pin
  #
  def pin_std_read_value(pin, mode, external_info)
    @external_info = external_info
    @ramps_arduino.execute_command("F42 P#{pin} M#{mode}", false, @status_debug_msg)
    @external_info = ''
  end

  # set standard pin mode
  #
  def pin_std_set_mode(pin, mode)
    @ramps_arduino.execute_command("F43 P#{pin} M#{mode}", false, @status_debug_msg)
  end

  # set pulse on standard pin
  #
  def pin_std_pulse(pin, value1, value2, time, mode)
    @ramps_arduino.execute_command("F44 P#{pin} V#{value1} W#{value2} T#{time} M#{mode}", false, @status_debug_msg)    
  end

  # dose an amount of water (in ml)
  #
  def dose_water(amount)
    #write_serial("F01 Q#{amount}")
  end

  ## arduino status

  # read end stop status from the device
  #
  def read_end_stops()
    @ramps_arduino.execute_command('F81', false, @status_debug_msg)
  end

  # read current coordinates from the device
  #
  def read_postition()
    @ramps_arduino.execute_command('F82', false, @status_debug_msg)
  end
  # read current software version
  #
  def read_device_version()
    @ramps_arduino.execute_command('F83', false, @status_debug_msg)
  end

  ## basic movements

  # move all axis home
  #
  def move_home_all
    $status.info_target_x = 0
    $status.info_target_y = 0
    $status.info_target_z = 0
    @ramps_arduino.execute_command('G28', true, false)
  end

  # move the bot to the home position
  #
  def move_home_x
    $status.info_target_x = 0
    @ramps_arduino.execute_command('F11', true, false)
  end

  # move the bot to the home position
  #
  def move_home_y
    $status.info_target_y = 0
    @ramps_arduino.execute_command('F12', true, false)
  end

  # move the bot to the home position
  #
  def move_home_z
    $status.info_target_z = 0
    @ramps_arduino.execute_command('F13', true, false)
  end

  # calibrate x axis
  #
  def calibrate_x
    $status.info_target_x = 0
    @ramps_arduino.execute_command('F14', true, false)
  end

  # calibrate y axis
  #
  def calibrate_y
    $status.info_target_y = 0
    @ramps_arduino.execute_command('F15', true, false)
  end

  # calibrate z axis
  #
  def calibrate_z
    $status.info_target_z = 0
    @ramps_arduino.execute_command('F16', true, false)
  end

  # move the bot to the give coordinates
  #
  def move_absolute( coord_x, coord_y, coord_z)

    # calculate the number of steps for the motors to do

    $status.info_target_x = coord_x
    $status.info_target_y = coord_y
    $status.info_target_z = coord_z

    steps_x = coord_x * @axis_x_steps_per_unit
    steps_y = coord_y * @axis_y_steps_per_unit
    steps_z = coord_z * @axis_z_steps_per_unit

    @axis_x_pos = steps_x
    @axis_y_pos = steps_y
    @axis_z_pos = steps_z

    move_to_coord(steps_x, steps_y, steps_z )

  end

  # move the bot a number of units starting from the current position
  #
  def move_relative( amount_x, amount_y, amount_z)

    # calculate the number of steps for the motors to do

    $status.info_target_x = @axis_x_pos_conv + amount_x
    $status.info_target_y = @axis_y_pos_conv + amount_y
    $status.info_target_z = @axis_z_pos_conv + amount_z

    steps_x = amount_x * @axis_x_steps_per_unit + @axis_x_pos
    steps_y = amount_y * @axis_y_steps_per_unit + @axis_y_pos
    steps_z = amount_z * @axis_z_steps_per_unit + @axis_z_pos

    @axis_x_pos = steps_x
    @axis_y_pos = steps_y
    @axis_z_pos = steps_z

    move_to_coord( steps_x, steps_y, steps_z )

  end

  # drive the motors so the bot is moved a number of steps
  #
  def move_steps(steps_x, steps_y, steps_z)
    execute_command("G00 X#{steps_x} Y#{steps_y} Z#{steps_z}")
  end

  # drive the motors so the bot is moved to a set location
  #
  def move_to_coord(steps_x, steps_y, steps_z)
    execute_command("G00 X#{steps_x} Y#{steps_y} Z#{steps_z}", true, false)
  end


  ## parameter hanlding

  # check to see of parameters in arduino are up to date
  #
  def check_parameters

    # read the parameter version in the database and in the device 
    read_parameter_from_device(0)
    @ramps_param.params.each do |p|
      if p['id'] == 0
        @param_version_ar = p['value_ar']
      end
    end

    @param_version_db = @bot_dbaccess.read_parameter_with_default('PARAM_VERSION', 0)

    # if the parameters in the device is different from the database parameter version
    # read and compare each parameter and write to device is different
    if @param_version_db != @param_version_ar
      @ramps_param.load_param_values_non_arduino()
      differences_found_total = false
      @ramps_param.params.each do |p|
        if p['id'] > 0
          difference = check_and_write_parameter(p)
          if difference then
            @params_in_sync = false
            differences_found_total = true
          end
        end
      end
      if !differences_found_total
        @params_in_sync = true
        write_parameter_to_device(0, @param_version_db)
      else
        @params_in_sync = false
      end
    end
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
