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