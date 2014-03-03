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
  def setPinMode()

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

  def disableMotor()
    @board.digital_write(@pin_enb, Firmata::Board::HIGH)
  end

  def enableMotor()
    @board.digital_write(@pin_enb, Firmata::Board::LOW)
  end

  def setDirectionLow()
    @board.digital_write(pin_dir, Firmata::Board::LOW)
    sleep @sleep_after_pin_set

    enableMotor()
  end

  def setDirectionHigh()
    @board.digital_write(pin_dir, Firmata::Board::HIGH)
    sleep @sleep_after_pin_set

    enableMotor()
  end

  # set the direction and enable pins to prepare for the move to the home position
  #
  def moveHomeSetDirection()

    if (invert_axis ^ reverse_home) == false
      setDirectionLow()
    else
      setDirectionHigh()
    end

  end

  # move the motor until the end stop is reached
  #
  def moveHome()

    moveHomeSetDirection()

    start = Time.now
    home  = 0

    # keep setting pulses at the step pin until the end stop is reached of a time is reached

    while home == 0 do

      @board.read_and_process
      span = Time.now - start

      if span > @move_home_timeout
        home = 1
        puts 'move home #{@name} timed out'
      end

      if (@board.pins[@pin_min].value == 1 and @reverse_home == false) or 
         (@board.pins[@pin_max].value == 1 and @reverse_home == true )
        home = 1
        puts 'end stop home #{@name} reached'
      end

      if home == 0
        setPulseOnPin(@pin_stp)
      end

    end

    # disable motor driver
    disableMotor()

    @pos = 0

  end

  # set a pulse on a pin with enough sleep time so firmata kan keep up
  #
  def setPulseOnPin(pin)
    @board.digital_write(pin, Firmata::Board::HIGH)
    sleep @sleep_after_pin_set
    @board.digital_write(pin, Firmata::Board::LOW)
    sleep @sleep_after_pin_set
  end


  # prepare the move by setting the direction and enable
  #
  def moveStepsPrepare(steps)

    @steps    = steps
    @nr_steps = steps.abs

    if (@steps < 0 and @invert_axis == false) or (@steps > 0 and @invert_axis == true)
      setDirectionLow()
    end

    if (@steps > 0 and @invert_axis == false) or (@steps < 0 and @invert_axis == true)
      setDirectionHigh()
    end

  end


  # move one motor a step if needed, while checking the end stops
  #
  def moveSteps()

      # check end stops

      if (@board.pins[@pin_min].value == 1 and @steps < 0) or
         (@board.pins[@pin_max].value == 1 and @steps > 0)
        @nr_steps = 0
        @pos      = @min if @steps < 0
        @pos      = @max if @steps > 0
        puts "end stop #{@name} reached"
      end

      # check minimum and maximum position

      if (@pos <= @min and @steps < 0) or (@pos >= @max and @steps > 0)
        @nr_steps = 0
        puts "end position reached #{@name}"
      end

      # send the step pulses to the motor drivers

      if @nr_steps > 0
        setPulseOnPin(@pin_stp)

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


    loadConfig()
    connectBoard()
    setPinNumbers()
    setBoardPinMode()

  end

  # set the hardware pin numbers
  #
  def setPinNumbers

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
  def connectBoard

    @boardDevice = "/dev/ttyACM0"
    @board = Firmata::Board.new @boardDevice
    @board.connect

    @axis_x.board = @board
    @axis_y.board = @board
    @axis_z.board = @board

  end

  # load the settings for the hardware
  # these are the timeouts and distance settings mainly
  def loadConfig

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
  def setBoardPinMode

    @axis_x.setPinMode()
    @axis_y.setPinMode()
    @axis_z.setPinMode()

  end

  # move the bot to the home position
  #
  def moveHomeX
    @axis_x.moveHome()
    @axis_x.disableMotor()
  end

  # move the bot to the home position
  #
  def moveHomeY
    @axis_y.moveHome()
    @axis_y.disableMotor()
  end

  # move the bot to the home position
  #
  def moveHomeZ
    @axis_z.moveHome()
    @axis_z.disableMotor()
  end

  def setSpeed( speed )

  end

  # move the bot to the give coordinates
  #
  def moveAbsolute( coord_x, coord_y, coord_z)

    puts '**move absolute **'

    # calculate the number of steps for the motors to do

    steps_x = (coord_x - @axis_x.pos_x) * @axis_x.steps_per_unit_x
    steps_y = (coord_y - @axis_y.pos_y) * @axis_y.steps_per_unit_y
    steps_z = (coord_z - @axis_z.pos_z) * @axis_z.steps_per_unit_z

    puts "x steps #{steps_x}"
    puts "y steps #{steps_y}"
    puts "z steps #{steps_z}"

    moveSteps(steps_x, steps_y, steps_z )

  end

  # move the bot a number of units starting from the current position
  #
  def moveRelative( amount_x, amount_y, amount_z)

    puts '**move relative **'

    # calculate the number of steps for the motors to do

    steps_x = amount_x * @axis_x.steps_per_unit
    steps_y = amount_y * @axis_y.steps_per_unit
    steps_z = amount_z * @axis_z.steps_per_unit

    puts "x steps #{steps_x}"
    puts "y steps #{steps_y}"
    puts "z steps #{steps_z}"

    moveSteps( steps_x, steps_y, steps_z )

  end

  # drive the motors so the bot is moved a number of steps
  #
  def moveSteps(steps_x, steps_y, steps_z)

    # set the direction and the enable bit for the motor drivers

    @axis_x.moveStepsPrepare(steps_x)
    @axis_y.moveStepsPrepare(steps_y)
    @axis_z.moveStepsPrepare(steps_z)

    # loop until all steps are done

    done_x = false
    done_y = false
    done_z = false

    while done_x == false or done_y == false or done_z == false do

      # read all input pins

      @board.read_and_process

      # move the motors
      done_x = @axis_x.moveSteps()
      done_y = @axis_y.moveSteps()
      done_z = @axis_z.moveSteps()

    end

    # disable motor drivers
    @axis_x.disableMotor()
    @axis_y.disableMotor()
    @axis_z.disableMotor()

  end
end
