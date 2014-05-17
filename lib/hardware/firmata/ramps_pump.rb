require 'firmata'

class HardwareInterfacePump

  attr_accessor :pin_pmp
  attr_accessor :seconds_per_unit
  attr_accessor :board

  def initialize
    @sleep_after_pin_set = 0.005
    @sleep_after_enable  = 0.001
  end

  # set the pins for one motor with sensors
  #
  def set_pin_mode()
    # set the pins for motor control to output
    @board.set_pin_mode(@pin_pmp, Firmata::Board::OUTPUT)
  end

  def start_pump()
    @board.digital_write(@pin_pmp, Firmata::Board::HIGH)
    sleep @sleep_after_pin_set
  end

  def stop_pump()
    @board.digital_write(@pin_pmp, Firmata::Board::LOW)
    sleep @sleep_after_pin_set
  end

  def dose_liquid(amount)
    start_pump()
    sleep amount * seconds_per_unit
    stop_pump()
  end

end