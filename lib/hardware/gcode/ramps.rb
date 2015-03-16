## HARDWARE INTERFACE
## ******************

# Communicate with the arduino using a serial interface
# All information is exchanged using a variation of g-code
# Parameters are stored in the database

#require 'serialport'

require_relative 'ramps_arduino.rb'
require_relative 'ramps_param.rb'

class HardwareInterface

  class << self
    attr_accessor :current

    def current
      @current ||= self.new(true)
    end
  end

  attr_reader :ramps_param, :ramps_main, :ramps_arduino

  # initialize the interface
  #
  def initialize(test_mode)

    @bot_dbaccess = DbAccess.current
    @test_mode         = test_mode

    # create the sub processing objects
    @ramps_param   = HardwareInterfaceParam.new
    @ramps_arduino = HardwareInterfaceArduino.new(test_mode)

    @ramps_arduino.ramps_param = @ramps_param
    @ramps_arduino.ramps_main  = self
    @ramps_param.ramps_arduino = @ramps_arduino
    @ramps_param.ramps_main    = self

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
    @ramps_arduino.external_info = external_info
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
    @ramps_arduino.execute_command("F01 Q#{amount.to_i}", false, @status_debug_msg)
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
    Status.current.info_target_x = 0
    Status.current.info_target_y = 0
    Status.current.info_target_z = 0
    @ramps_arduino.execute_command('G28', true, false)
  end

  # move the bot to the home position
  #
  def move_home_x
    Status.current.info_target_x = 0
    @ramps_arduino.execute_command('F11', true, false)
  end

  # move the bot to the home position
  #
  def move_home_y
    Status.current.info_target_y = 0
    @ramps_arduino.execute_command('F12', true, false)
  end

  # move the bot to the home position
  #
  def move_home_z
    Status.current.info_target_z = 0
    @ramps_arduino.execute_command('F13', true, false)
  end

  # calibrate x axis
  #
  def calibrate_x
    Status.current.info_target_x = 0
    @ramps_arduino.execute_command('F14', true, false)
  end

  # calibrate y axis
  #
  def calibrate_y
    Status.current.info_target_y = 0
    @ramps_arduino.execute_command('F15', true, false)
  end

  # calibrate z axis
  #
  def calibrate_z
    Status.current.info_target_z = 0
    @ramps_arduino.execute_command('F16', true, false)
  end

  # move the bot to the give coordinates
  #
  def move_absolute( coord_x, coord_y, coord_z)

    Status.current.info_target_x = coord_x
    Status.current.info_target_y = coord_y
    Status.current.info_target_z = coord_z

    # calculate the number of steps for the motors to do

    steps_x = coord_x * @ramps_param.axis_x_steps_per_unit
    steps_y = coord_y * @ramps_param.axis_y_steps_per_unit
    steps_z = coord_z * @ramps_param.axis_z_steps_per_unit

    move_to_coord(steps_x, steps_y, steps_z )

  end

  # move the bot a number of units starting from the current position
  #
  def move_relative( amount_x, amount_y, amount_z)

    # calculate the number of steps for the motors to do

    Status.current.info_target_x = Status.current.info_current_x + amount_x
    Status.current.info_target_y = Status.current.info_current_y + amount_y
    Status.current.info_target_z = Status.current.info_current_z + amount_z

    steps_x = amount_x * @ramps_param.axis_x_steps_per_unit + Status.current.info_current_x_steps
    steps_y = amount_y * @ramps_param.axis_y_steps_per_unit + Status.current.info_current_y_steps
    steps_z = amount_z * @ramps_param.axis_z_steps_per_unit + Status.current.info_current_z_steps

    move_to_coord( steps_x, steps_y, steps_z )

  end

  # drive the motors so the bot is moved a number of steps
  #
  def move_steps(steps_x, steps_y, steps_z)
    @ramps_arduino.execute_command("G01 X#{steps_x.to_i} Y#{steps_y.to_i} Z#{steps_z.to_i}", true, false)
  end

  # drive the motors so the bot is moved to a set location
  #
  def move_to_coord(steps_x, steps_y, steps_z)
    @ramps_arduino.execute_command("G00 X#{steps_x.to_i} Y#{steps_y.to_i} Z#{steps_z.to_i}", true, false)
  end

  ## parameter hanlding

  def check_parameters
     @ramps_param.check_parameters()
  end

end
