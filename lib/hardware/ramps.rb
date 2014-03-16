require 'firmata'
require_relative 'ramps_axis'
require_relative 'ramps_pump'

class HardwareInterface

  # initialize the interface
  #
  def initialize

    @axis_x = HardwareInterfaceAxis.new
    @axis_y = HardwareInterfaceAxis.new
    @axis_z = HardwareInterfaceAxis.new
    @pump_w = HardwareInterfacePump.new

    load_config()
    connect_board()
    set_pin_numbers()
    set_board_pin_mode()

  end

  # set the hardware pin numbers
  #
  def set_pin_numbers

    @pin_led = 13

    @axis_x.name = 'X'
    @axis_x.pin_stp = 54
    @axis_x.pin_dir = 55
    @axis_x.pin_enb = 38
    @axis_x.pin_min = 3
    @axis_x.pin_max = 2

    @axis_y.name = 'Y'
    @axis_y.pin_stp = 60
    @axis_y.pin_dir = 61
    @axis_y.pin_enb = 56
    @axis_y.pin_min = 14
    @axis_y.pin_max = 15

    @axis_z.name = 'Z'
    @axis_z.pin_stp = 46
    @axis_z.pin_dir = 48
    @axis_z.pin_enb = 62
    @axis_z.pin_min = 18
    @axis_z.pin_max = 19

    @pump_w.pin_pmp = 8

  end

  # connect to the serial port and start communicating with the arduino/firmata protocol
  #
  def connect_board

    @boardDevice = "/dev/ttyACM0"
    @board = Firmata::Board.new @boardDevice
    @board.connect

    @axis_x.board = @board
    @axis_y.board = @board
    @axis_z.board = @board
    @pump_w.board = @board

  end

  # load the settings for the hardware
  # these are the timeouts and distance settings mainly
  def load_config

    @axis_x.move_home_timeout   = 15 # seconds after which home command is aborted
    @axis_y.move_home_timeout   = 15
    @axis_z.move_home_timeout   = 150

    @axis_x.invert_axis = false
    @axis_y.invert_axis = false
    @axis_z.invert_axis = false

    @axis_x.steps_per_unit = 5 # steps per milimeter for example
    @axis_y.steps_per_unit = 4
    @axis_z.steps_per_unit = 157

    @axis_x.max = 220
    @axis_y.max = 128
    @axis_z.max = 0

    @axis_x.min = 0
    @axis_y.min = 0
    @axis_z.min = -70
 
    @axis_x.reverse_home = false
    @axis_y.reverse_home = false
    @axis_z.reverse_home = true

    @pump_w.seconds_per_unit = 0.6 # seconds per mililiter

  end

  # set motor driver and end stop pins to input or output output and set enables for the drivers to off
  #
  def set_board_pin_mode

    @axis_x.set_pin_mode()
    @axis_y.set_pin_mode()
    @axis_z.set_pin_mode()
    @pump_w.set_pin_mode()

  end

  # move the bot to the home position
  #
  def move_home_x
    @axis_x.move_home()
    @axis_x.disable_motor()
  end

  # move the bot to the home position
  #
  def move_home_y
    @axis_y.move_home()
    @axis_y.disable_motor()
  end

  # move the bot to the home position
  #
  def move_home_z
    @axis_z.move_home()
    @axis_z.disable_motor()
  end

  def set_speed( speed )

  end

  # move the bot to the give coordinates
  #
  def move_absolute( coord_x, coord_y, coord_z)

    puts '**move absolute **'

    # calculate the number of steps for the motors to do

    steps_x = (coord_x - @axis_x.pos) * @axis_x.steps_per_unit
    steps_y = (coord_y - @axis_y.pos) * @axis_y.steps_per_unit
    steps_z = (coord_z - @axis_z.pos) * @axis_z.steps_per_unit

    puts "x steps #{steps_x}"
    puts "y steps #{steps_y}"
    puts "z steps #{steps_z}"

    move_steps(steps_x, steps_y, steps_z )

  end

  # move the bot a number of units starting from the current position
  #
  def move_relative( amount_x, amount_y, amount_z)

    puts '**move relative **'

    # calculate the number of steps for the motors to do

    steps_x = amount_x * @axis_x.steps_per_unit
    steps_y = amount_y * @axis_y.steps_per_unit
    steps_z = amount_z * @axis_z.steps_per_unit

    puts "x steps #{steps_x}"
    puts "y steps #{steps_y}"
    puts "z steps #{steps_z}"

    move_steps( steps_x, steps_y, steps_z )

  end

  # drive the motors so the bot is moved a number of steps
  #
  def move_steps(steps_x, steps_y, steps_z)

    # set the direction and the enable bit for the motor drivers

    @axis_x.move_steps_prepare(steps_x)
    @axis_y.move_steps_prepare(steps_y)
    @axis_z.move_steps_prepare(steps_z)

    # loop until all steps are done

    done_x = false
    done_y = false
    done_z = false

    while done_x == false or done_y == false or done_z == false do

      # read all input pins

      @board.read_and_process

      # move the motors
      done_x = @axis_x.move_steps()
      done_y = @axis_y.move_steps()
      done_z = @axis_z.move_steps()

    end

    # disable motor drivers
    @axis_x.disable_motor()
    @axis_y.disable_motor()
    @axis_z.disable_motor()

  end

  def dose_water(amount)
    @pump_w.dose_liquid(amount)
  end

end
