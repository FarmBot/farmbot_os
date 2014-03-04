require 'firmata'

class HardwareInterfaceAxis

  attr_accessor :pos, :name, :pin_stp, :pin_dir
  attr_accessor :pin_enb, :pin_min, :pin_max, :min, :max
  attr_accessor :move_home_timeout, :invert_axis, :steps_per_unit
  attr_accessor :reverse_home, :board

  def initialize
    @pos = 0.0
    @sleep_after_pin_set = 0.005
    @sleep_after_enable  = 0.001

    @steps = 0
    @nr_steps = 0
  end

  # set the pins for one motor with sensors
  #
  def set_pin_mode()

    # set the pins for motor control to output
    @board.set_pin_mode(pin_enb, Firmata::Board::OUTPUT)
    @board.set_pin_mode(pin_dir, Firmata::Board::OUTPUT)
    @board.set_pin_mode(pin_stp, Firmata::Board::OUTPUT)

    # set the pins for end stops to input
    @board.set_pin_mode(pin_min, Firmata::Board::INPUT)
    @board.set_pin_mode(pin_max, Firmata::Board::INPUT)

    # disable motors
    @board.digital_write(pin_enb, Firmata::Board::HIGH)

    # start reading end stops
    @board.toggle_pin_reporting(pin_min)
    @board.toggle_pin_reporting(pin_max)
    
  end

  def disable_motor()
    @board.digital_write(@pin_enb, Firmata::Board::HIGH)
  end

  def enable_motor()
    @board.digital_write(@pin_enb, Firmata::Board::LOW)
  end

  def set_direction_low()
    @board.digital_write(pin_dir, Firmata::Board::LOW)
    sleep @sleep_after_pin_set

    enable_motor()
  end

  def set_direction_high()
    @board.digital_write(pin_dir, Firmata::Board::HIGH)
    sleep @sleep_after_pin_set

    enable_motor()
  end

  # set the direction and enable pins to prepare for the move to the home position
  #
  def move_home_set_direction()

    if (invert_axis ^ reverse_home) == false
      set_direction_low()
    else
      set_direction_high()
    end

  end

  # move the motor until the end stop is reached
  #
  def move_home()

    move_home_set_direction()

    start = Time.now
    home  = 0

    # keep setting pulses at the step pin until the end stop is reached of a time is reached

    while home == 0 do

      @board.read_and_process
      span = Time.now - start

      if span > @move_home_timeout
        home = 1
        puts "move home #{@name} timed out"
      end

      if @board.pins[@pin_min].value == 1 and @reverse_home == false
        home = 1
        puts "end stop home min #{@name} reached"
      end

      if @board.pins[@pin_max].value == 1 and @reverse_home == true
        home = 1
        puts "end stop home max #{@name} reached"
      end

      if home == 0
        set_pulse_on_pin(@pin_stp)
      end

    end

    # disable motor driver
    disable_motor()

    @pos = 0

  end

  # set a pulse on a pin with enough sleep time so firmata kan keep up
  #
  def set_pulse_on_pin(pin)
    @board.digital_write(pin, Firmata::Board::HIGH)
    sleep @sleep_after_pin_set
    @board.digital_write(pin, Firmata::Board::LOW)
    sleep @sleep_after_pin_set
  end


  # prepare the move by setting the direction and enable
  #
  def move_steps_prepare(steps)

    @steps    = steps
    @nr_steps = steps.abs

    if (@steps < 0 and @invert_axis == false) or (@steps > 0 and @invert_axis == true)
      set_direction_low()
    end

    if (@steps > 0 and @invert_axis == false) or (@steps < 0 and @invert_axis == true)
      set_direction_high()
    end

  end


  # move one motor a step if needed, while checking the end stops
  #
  def move_steps()

      # check end stops

      if @board.pins[@pin_min].value == 1 and @steps < 0
        @nr_steps = 0
        @pos      = @min
        puts "end stop min #{@name} reached"
      end

      if @board.pins[@pin_max].value == 1 and @steps > 0
        @nr_steps = 0
        @pos      = @max
        puts "end stop max #{@name} reached"
      end

      # check minimum and maximum position

      if (@pos <= @min and @steps < 0) or (@pos >= @max and @steps > 0)
        @nr_steps = 0
        puts "end position reached #{@name}"
      end

      # send the step pulses to the motor drivers

      if @nr_steps > 0
        set_pulse_on_pin(@pin_stp)

        @pos      += 1.0 / @steps_per_unit * (@steps<=>0.0)
        @nr_steps -= 1

        return false
      else
        return true
      end

  end

end

class HardwareInterface

  # initialize the interface
  #
  def initialize

    @axis_x = HardwareInterfaceAxis.new
    @axis_y = HardwareInterfaceAxis.new
    @axis_z = HardwareInterfaceAxis.new


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

  end

  # set motor driver and end stop pins to input or output output and set enables for the drivers to off
  #
  def set_board_pin_mode

    @axis_x.set_pin_mode()
    @axis_y.set_pin_mode()
    @axis_z.set_pin_mode()

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

    steps_x = (coord_x - @axis_x.pos_x) * @axis_x.steps_per_unit_x
    steps_y = (coord_y - @axis_y.pos_y) * @axis_y.steps_per_unit_y
    steps_z = (coord_z - @axis_z.pos_z) * @axis_z.steps_per_unit_z

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
end
