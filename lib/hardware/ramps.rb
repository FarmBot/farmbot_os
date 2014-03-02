require 'firmata'

class HardwareInterface

  # initialize the interface
  #
  def initialize

    @pos_x = 0.0
    @pos_y = 0.0
    @pos_z = 0.0

    loadConfig()
    connectBoard()
    setPinNumbers()
    setBoardPinMode()

  end

  # set the hardware pin numbers
  #
  def setPinNumbers

    @pin_led = 13

    @pin_stp_x = 54
    @pin_dir_x = 55
    @pin_enb_x = 38

    @pin_stp_y = 60
    @pin_dir_y = 61
    @pin_enb_y = 56

    @pin_stp_z = 46
    @pin_dir_z = 48
    @pin_enb_z = 62

    @pin_min_x = 3
    @pin_max_x = 2

    @pin_min_y = 14
    @pin_max_y = 15

    @pin_min_z = 18
    @pin_max_z = 19

  end

  # connect to the serial port and start communicating with the arduino/firmata protocol
  #
  def connectBoard

    @boardDevice = "/dev/ttyACM0"
    @board = Firmata::Board.new @boardDevice
    @board.connect

  end

  # load the settings for the hardware
  # these are the timeouts and distance settings mainly
  def loadConfig

    @move_home_timeout_x   = 15 # seconds after which home command is aborted
    @move_home_timeout_y   = 15
    @move_home_timeout_z   = 150

    @sleep_after_pin_set = 0.005
    @sleep_after_enable  = 0.001

    @invert_axis_x = false
    @invert_axis_y = false
    @invert_axis_z = false

    @steps_per_unit_x = 5 # steps per milimeter for example
    @steps_per_unit_y = 4
    @steps_per_unit_z = 157

    @max_x = 230
    @max_y = 128
    @max_z = 0

    @min_x = 0
    @min_y = 0
    @min_z = -70

  end

  # set motor driver and end stop pins to input or output output and set enables for the drivers to off
  #
  def setBoardPinMode

    setAxisPinMode(@pin_enb_x, @pin_dir_x, @pin_stp_x, @pin_min_x, @pin_max_x)
    setAxisPinMode(@pin_enb_y, @pin_dir_y, @pin_stp_y, @pin_min_y, @pin_max_y)
    setAxisPinMode(@pin_enb_z, @pin_dir_z, @pin_stp_z, @pin_min_z, @pin_max_z)

  end

  # set the pins for one motor with sensors
  #
  def setAxisPinMode(pin_enb, pin_dir, pin_stp, pin_min, pin_max)

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

  # move the bot to the home position
  #
  def moveHomeX
    moveHome(@pin_enb_x, @pin_dir_x, @pin_stp_x, @pin_min_x, @invert_axis_x, false, @move_home_timeout_x)
    @pos_x = 0
  end

  # move the bot to the home position
  #
  def moveHomeY
    moveHome(@pin_enb_y, @pin_dir_y, @pin_stp_y, @pin_min_y, @invert_axis_y, false, @move_home_timeout_y)
    @pos_y = 0
  end

  # move the bot to the home position
  #
  def moveHomeZ
    moveHome(@pin_enb_z, @pin_dir_z, @pin_stp_z, @pin_max_z, @invert_axis_z, true, @move_home_timeout_z)
    @pos_z = 0
  end

  def setSpeed( speed )

  end

  # set the direction and enable pins to prepare for the move to the home position
  #
  def moveHomeSetDirection(pin_enb, pin_dir, invert_axis, reverse)

    @board.digital_write(pin_enb, Firmata::Board::LOW)
    sleep @sleep_after_enable

    if (invert_axis ^ reverse) == false
      @board.digital_write(pin_dir, Firmata::Board::LOW)
    else
      @board.digital_write(pin_dir, Firmata::Board::HIGH)
    end
    sleep @sleep_after_pin_set

  end

  # move the motor until the end stop is reached
  #
  def moveHome(pin_enb, pin_dir, pin_stp, pin_min, invert_axis, reverse, timeout)

    moveHomeSetDirection(pin_enb, pin_dir, invert_axis, reverse)

    start = Time.now
    home  = 0

    # keep setting pulses at the step pin until the end stop is reached of a time is reached

    while home == 0 do

      @board.read_and_process
      span = Time.now - start

      if span > timeout
        home = 1
        puts 'move home timed out'
      end

      if @board.pins[pin_min].value == 1
        home = 1
        puts 'end stop reached'
      end

      if home == 0
        setPulseOnPin(pin_stp)
      end
    end

    # disable motor driver
    @board.digital_write(pin_dir, Firmata::Board::LOW)

  end

  # set a pulse on a pin with enough sleep time so firmata kan keep up
  #
  def setPulseOnPin(pin)
        @board.digital_write(pin, Firmata::Board::HIGH)
        sleep @sleep_after_pin_set
        @board.digital_write(pin, Firmata::Board::LOW)
        sleep @sleep_after_pin_set
  end


  # move the bot to the give coordinates
  #
  def moveAbsolute( coord_x, coord_y, coord_z)

    puts '**move absolute **'

    # calculate the number of steps for the motors to do

    steps_x = (coord_x - @pos_x) * @steps_per_unit_x
    steps_y = (coord_y - @pos_y) * @steps_per_unit_y
    steps_z = (coord_z - @pos_z) * @steps_per_unit_z

    puts "x steps #{steps_x}"
    puts "y steps #{steps_y}"
    puts "z steps #{steps_z}"

    moveSteps( steps_x, steps_y, steps_z )

  end

  # move the bot a number of units starting from the current position
  #
  def moveRelative( amount_x, amount_y, amount_z)

    puts '**move relative **'

    # calculate the number of steps for the motors to do

    steps_x = amount_x * @steps_per_unit_x
    steps_y = amount_y * @steps_per_unit_y
    steps_z = amount_z * @steps_per_unit_z

    puts "x steps #{steps_x}"
    puts "y steps #{steps_y}"
    puts "z steps #{steps_z}"

    moveSteps( steps_x, steps_y, steps_z )

  end

  # prepare the move by setting the direction and enable
  #
  def moveStepsPrepare(steps, pin_enb, pin_dir, invert_axis)

    if (steps < 0 and invert_axis == false) or (steps > 0 and invert_axis == true)
      @board.digital_write(pin_enb, Firmata::Board::LOW)
      @sleep_after_enable
      @board.digital_write(pin_dir, Firmata::Board::LOW)
      @sleep_after_pin_set
    end

    if (steps > 0 and invert_axis == false) or (steps < 0 and invert_axis == true)
      @board.digital_write(pin_enb, Firmata::Board::LOW)
      @sleep_after_enable
      @board.digital_write(pin_dir, Firmata::Board::HIGH)
      @sleep_after_pin_set
    end

  end

  # move one motor a step if needed, while checking the end stops
  #
  def moveStepsAxis(axis_info, pin_enb, pin_stp, pin_min, pin_max, min, max, steps_per_unit)

      # check end stops

      pos        = axis_info[:pos]
      nr_steps   = axis_info[:nr_steps]
      steps      = axis_info[:steps]

      if @board.pins[pin_min].value == 1 and steps < 0
        nr_steps = 0
        pos      = min
        puts "end stop min #{axis_info[:name]}"
      end

      if @board.pins[pin_max].value == 1 and steps > 0
        nr_steps = 0
        pos_new  = max
        puts "end stop max #{axis_info[:name]}"
      end

      # check minimum and maximum position

      if pos >= max and steps > 0
        nr_steps = 0
        puts "maximum position reached #{axis_info[:name]}"
      end

      if pos <= min and steps < 0
        nr_steps = 0
        puts "minimum position for #{axis_info[:name]} reached"
      end

      # send the step pulses to the motor drivers

      if nr_steps > 0
        setPulseOnPin(pin_stp)

        pos      += 1.0 / steps_per_unit * (steps<=>0.0)
        nr_steps -= 1
      end

      axis_info[:pos]      = pos
      axis_info[:nr_steps] = nr_steps

  end

  # drive the motors so the bot is moved a number of steps
  #
  def moveSteps(steps_x, steps_y, steps_z)

    # set the direction and the enable bit for the motor drivers

    moveStepsPrepare(steps_x, @pin_enb_x, @pin_dir_x, @invert_axis_x)
    moveStepsPrepare(steps_y, @pin_enb_y, @pin_dir_y, @invert_axis_y)
    moveStepsPrepare(steps_z, @pin_enb_z, @pin_dir_z, @invert_axis_z)

    # make the steps positive numbers

    axis_info_x = {:name => "X", :steps => steps_x, :nr_steps => steps_x.abs, :pos => @pos_x }
    axis_info_y = {:name => "Y", :steps => steps_y, :nr_steps => steps_y.abs, :pos => @pos_y }
    axis_info_z = {:name => "Z", :steps => steps_z, :nr_steps => steps_z.abs, :pos => @pos_z }

    nr_steps_x = steps_x.abs
    nr_steps_y = steps_y.abs
    nr_steps_z = steps_z.abs

    # loop until all steps are done

    while axis_info_x[:nr_steps] > 0 or axis_info_y[:nr_steps] > 0 or axis_info_z[:nr_steps] > 0 do

      # read all input pins

      @board.read_and_process

      # move the motors
      moveStepsAxis(axis_info_x, @pin_enb_x, @pin_stp_x, @pin_min_x, @pin_max_x, @min_x, @max_x, @steps_per_unit_x)
      moveStepsAxis(axis_info_y, @pin_enb_y, @pin_stp_y, @pin_min_y, @pin_max_y, @min_y, @max_y, @steps_per_unit_y)
      moveStepsAxis(axis_info_z, @pin_enb_z, @pin_stp_z, @pin_min_z, @pin_max_z, @min_z, @max_z, @steps_per_unit_z)

    end

    @pos_x = axis_info_x[:pos] 
    @pos_y = axis_info_y[:pos] 
    @pos_z = axis_info_z[:pos]

    # disable motor drivers

    @board.digital_write(@pin_enb_x, Firmata::Board::HIGH)
    @board.digital_write(@pin_enb_y, Firmata::Board::HIGH)
    @board.digital_write(@pin_enb_z, Firmata::Board::HIGH)

  end
end
