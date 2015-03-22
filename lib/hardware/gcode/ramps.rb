## HARDWARE INTERFACE
## ******************

# Communicate with the arduino using a serial interface
# All information is exchanged using a variation of g-code
# Parameters are stored in the database

#require 'serialport'

require_relative 'ramps_arduino.rb'
require_relative 'ramps_param.rb'


class HardwareInterface

  attr_reader :ramps_param, :ramps_main, :ramps_arduino

  attr_reader   :target_x , :target_y , :target_z
  attr_reader   :current_x, :current_y, :current_z

  attr_reader   :end_stop_x_a, :end_stop_y_a, :end_stop_z_a
  attr_reader   :end_stop_x_b, :end_stop_y_b, :end_stop_z_b

  attr_accessor :axis_x_steps_per_unit, :axis_y_steps_per_unit, :axis_z_steps_per_unit

  attr_reader :return_values
  attr_reader :software_version


  # initialize the interface
  #
  def initialize(test_mode)

    #@bot_dbaccess = $bot_dbaccess
    @test_mode         = test_mode

    # create the sub processing objects
    #@ramps_param   = HardwareInterfaceParam.new
    @ramps_arduino = HardwareInterfaceArduino.new(test_mode)

    @ramps_arduino.ramps_param = @ramps_param
    @ramps_arduino.ramps_main  = self
    @ramps_param.ramps_arduino = @ramps_arduino
    @ramps_param.ramps_main    = self

    @external_info = ""

    @current_x_steps = 0
    @current_y_steps = 0
    @current_z_steps = 0

    @axis_x_steps_per_unit = 100
    @axis_y_steps_per_unit = 100
    @axis_z_steps_per_unit = 100

    @return_values = Queue.new

  end


  ## SERIAL COMMUNICATION
  ## ********************

  def start_command(text, log, onscreen)
    @ramps_arduino.execute_command("F61 P#{pin} V#{value}", false, @status_debug_msg)
  end
  

  ## INTERFACE FUNCTIONS
  ## *******************

  def prepare
    @external_info = ""
  end

  ## control additional I/O (servo, pins, water)

  # move a servo
  #
  def servo_std_move(pin, value)
    start_command("F61 P#{pin} V#{value}", false, @status_debug_msg)
  end

  # set standard pin value
  #
  def pin_std_set_value(pin, value, mode)
    start_command("F41 P#{pin} V#{value} M#{mode}", false, @status_debug_msg)
  end

  # read standard pin
  #
  def pin_std_read_value(pin, mode, external_info)
    @external_info = external_info
    start_command("F42 P#{pin} M#{mode}", false, @status_debug_msg)
    @external_info = ''
  end

  # set standard pin mode
  #
  def pin_std_set_mode(pin, mode)
    start_command("F43 P#{pin} M#{mode}", false, @status_debug_msg)
  end

  # set pulse on standard pin
  #
  def pin_std_pulse(pin, value1, value2, time, mode)
    start_command("F44 P#{pin} V#{value1} W#{value2} T#{time} M#{mode}", false, @status_debug_msg)    
  end

  # dose an amount of water (in ml)
  #
  def dose_water(amount)
    start_command("F01 Q#{amount.to_i}", false, @status_debug_msg)
  end

  ## arduino status

  # read end stop status from the device
  #
  def read_end_stops()
    start_command('F81', false, @status_debug_msg)
  end

  # read current coordinates from the device
  #
  def read_postition()
    start_command('F82', false, @status_debug_msg)
  end
  # read current software version
  #
  def read_device_version()
    start_command('F83', false, @status_debug_msg)
  end

  ## basic movements

  # move all axis home
  #
  def move_home_all
    @target_x = 0
    @target_y = 0
    @target_z = 0
    start_command('G28', true, false)
  end

  # move the bot to the home position
  #
  def move_home_x
    @target_x = 0
    start_command('F11', true, false)
  end

  # move the bot to the home position
  #
  def move_home_y
    @target_y = 0
    start_command('F12', true, false)
  end

  # move the bot to the home position
  #
  def move_home_z
    @target_z = 0
    start_command('F13', true, false)
  end

  # calibrate x axis
  #
  def calibrate_x
    @target_x = 0
    start_command('F14', true, false)
  end

  # calibrate y axis
  #
  def calibrate_y
    @target_y = 0
    start_command('F15', true, false)
  end

  # calibrate z axis
  #
  def calibrate_z
    @target_z = 0
    start_command('F16', true, false)
  end

  # move the bot to the give coordinates
  #
  def move_absolute( coord_x, coord_y, coord_z)

    @target_x = coord_x
    @target_y = coord_y
    @target_z = coord_z

    # calculate the number of steps for the motors to do

    steps_x = coord_x * @axis_x_steps_per_unit
    steps_y = coord_y * @axis_y_steps_per_unit
    steps_z = coord_z * @axis_z_steps_per_unit

    move_to_coord(steps_x, steps_y, steps_z )

  end

  # move the bot a number of units starting from the current position
  #
  def move_relative( amount_x, amount_y, amount_z)

    # calculate the number of steps for the motors to do

    @target_x = @current_x + amount_x
    @target_y = @current_y + amount_y
    @target_z = @current_z + amount_z

    steps_x = amount_x * @axis_x_steps_per_unit + @current_x_steps
    steps_y = amount_y * @axis_y_steps_per_unit + @current_y_steps
    steps_z = amount_z * @axis_z_steps_per_unit + @current_z_steps

    move_to_coord( steps_x, steps_y, steps_z )

  end

  # drive the motors so the bot is moved a number of steps
  #
  def move_steps(steps_x, steps_y, steps_z)
    start_command("G01 X#{steps_x.to_i} Y#{steps_y.to_i} Z#{steps_z.to_i}", true, false)
  end

  # drive the motors so the bot is moved to a set location
  #
  def move_to_coord(steps_x, steps_y, steps_z)
    start_command("G00 X#{steps_x.to_i} Y#{steps_y.to_i} Z#{steps_z.to_i}", true, false)
  end

  def emergency_stop
    @ramps_arduino.emergency_stop
  end

  ## parameter handling

  def check_feedback

    # first let arduino read all parameters
    @ramps_arduino.check_parameters()
    while !@ramps.return_values.is_empty?
      value = @ramps.return_values.pop
      case value.code
        # report end stops
        when 'R81'
          @end_stop_x_a = value.xa
          @end_stop_x_b = value.xb
          @end_stop_y_a = value.ya
          @end_stop_y_b = value.yb
          @end_stop_z_a = value.za
          @end_stop_z_b = value.zb

        # report position
        when 'R82'
          @current_x_steps = value.x
          @current_y_steps = value.y
          @current_z_steps = value.z

          @current_x = @current_x_steps * @axis_x_steps_per_unit
          @current_y = @current_y_steps * @axis_y_steps_per_unit
          @current_z = @current_z_steps * @axis_z_steps_per_unit

        # report software version
        when 'R83'
          @software_version = value.text

        # comment
        when 'R99'
          puts ">#{value.text}<"

        # add all others to the list for processing elsewhere
        else
          value.external_info = @external_info
          @return_values << value
      end
    end

  end

  def is_busy
    @ramps.is_busy
  end

  def is_done
    @ramps.is_done
  end

  def is_error
    @ramps.is_error
  end

end 
