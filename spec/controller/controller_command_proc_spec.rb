require 'spec_helper'
require './lib/status.rb'
require './lib/database/dbaccess.rb'
require './lib/controller_command_proc.rb'
require './lib/hardware/gcode/ramps.rb'
require './app/models/command.rb'
require './app/models/command_line.rb'

describe ControllerCommandProc do

  before do
    DbAccess.current = DbAccess.new('development')
    DbAccess.current = DbAccess.current
    DbAccess.current.disable_log_to_screen()

    Status.current = Status.new

    HardwareInterface.current = HardwareInterface.new(true)
    @ramps = HardwareInterface.current

    @controller = ControllerCommandProc.new

    $hardware_sim = 0
  end

#  def move_absolute(command_line)

  it "move absolute" do


    x      = rand(9999999).to_i
    y      = rand(9999999).to_i
    z      = rand(9999999).to_i

    command_line = CommandLine.new
    command_line.coord_x = x
    command_line.coord_y = y
    command_line.coord_z = z

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    @controller.move_absolute(command_line)

    part_x = "X#{x * @ramps.ramps_param.axis_x_steps_per_unit}"
    part_y = "Y#{y * @ramps.ramps_param.axis_y_steps_per_unit}"
    part_z = "Z#{z * @ramps.ramps_param.axis_z_steps_per_unit}"

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("G00 #{part_x} #{part_y} #{part_z}\n")
  end

#  def move_relative(command_line)

  it "move relative" do

    x         = rand(9999999).to_i
    y         = rand(9999999).to_i
    z         = rand(9999999).to_i

    current_x = rand(9999999).to_i
    current_y = rand(9999999).to_i
    current_z = rand(9999999).to_i

    Status.current.info_current_x_steps = current_x
    Status.current.info_current_y_steps = current_y
    Status.current.info_current_z_steps = current_z

    command_line = CommandLine.new
    command_line.coord_x = x
    command_line.coord_y = y
    command_line.coord_z = z

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    @controller.move_relative(command_line)

    part_x = "X#{x * @ramps.ramps_param.axis_x_steps_per_unit + current_x}"
    part_y = "Y#{y * @ramps.ramps_param.axis_y_steps_per_unit + current_y}"
    part_z = "Z#{z * @ramps.ramps_param.axis_z_steps_per_unit + current_z}"

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("G00 #{part_x} #{part_y} #{part_z}\n")
  end

#  def home_x(command_line)

  it "home x" do

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    command_line = CommandLine.new
    @controller.home_x(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F11\n")
  end

#  def home_y(command_line)

  it "home y" do

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    command_line = CommandLine.new
    @controller.home_y(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F12\n")
  end

#  def home_z(command_line)

  it "home z" do

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    command_line = CommandLine.new
    @controller.home_z(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F13\n")

  end

#  def calibration_x(command_line)

  it "calibrate x" do

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    command_line = CommandLine.new
    @controller.calibration_x(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F14\n")

  end

#  def calibration_y(command_line)

  it "calibrate y" do

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    command_line = CommandLine.new
    @controller.calibration_y(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F15\n")

  end

#  def calibration_z(command_line)

  it "calibrate z" do

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    command_line = CommandLine.new
    @controller.calibration_z(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F16\n")

  end

#  def dose_water(command_line)

  it "dose water" do

    amount    = rand(9999999).to_i

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    command_line = CommandLine.new
    command_line.amount = amount
    @controller.dose_water(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F01 Q#{amount}\n")

  end

#  def pin_write(command_line)

  it "pin write" do

    pin      = rand(9999999).to_i
    value    = rand(9999999).to_i
    mode     = rand(9999999).to_i

    command_line = CommandLine.new
    command_line.pin_nr      = pin
    command_line.pin_value_1 = value
    command_line.pin_mode    = mode

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    @controller.pin_write(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F41 P#{pin} V#{value} M#{mode}\n")
  end

#  def pin_read(command_line)

  it "pin read" do

    pin      = rand(9999999).to_i
    mode     = rand(9999999).to_i
    value    = rand(9999999).to_i
    ext_info = rand(9999999).to_s

    command_line = CommandLine.new
    command_line.pin_nr        = pin
    command_line.pin_value_1   = value
    command_line.pin_mode      = mode
    command_line.external_info = ext_info

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    @controller.pin_read(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F42 P#{pin} M#{mode}\n")
  end

#  def pin_mode(command_line)

  it "pin mode" do

    pin      = rand(9999999).to_i
    mode     = rand(9999999).to_i

    command_line = CommandLine.new
    command_line.pin_nr        = pin
    command_line.pin_mode      = mode

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    @controller.pin_mode(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F43 P#{pin} M#{mode}\n")
  end


#  def pin_pulse(command_line)

  it "pin pulse" do

    pin      = rand(9999999).to_i
    mode     = rand(9999999).to_i
    value_1  = rand(9999999).to_i
    value_2  = rand(9999999).to_i
    time     = rand(9999999).to_i

    command_line = CommandLine.new
    command_line.pin_nr        = pin
    command_line.pin_mode      = mode
    command_line.pin_value_1   = value_1
    command_line.pin_value_2   = value_2
    command_line.pin_time      = time

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    @controller.pin_pulse(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F44 P#{pin} V#{value_1} W#{value_2} T#{time} M#{mode}\n")
  end

#  def servo_move(command_line)

  it "servo move" do

    pin      = rand(9999999).to_i
    value    = rand(9999999).to_i

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    command_line = CommandLine.new
    command_line.pin_nr        = pin
    command_line.pin_value_1   = value
    @controller.servo_move(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F61 P#{pin} V#{value}\n")
  end

#  def send_command(command_line)

  it "send command" do

    pin      = rand(9999999).to_i
    value    = rand(9999999).to_i

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    command_line = CommandLine.new
    command_line.action       = 'SERVO MOVE'
    command_line.pin_nr        = pin
    command_line.pin_value_1   = value
    @controller.send_command(command_line)

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F61 P#{pin} V#{value}\n")

    $hardware_sim = 1

    @ramps.ramps_arduino.serial_port.test_serial_write = ""
    @controller.send_command(command_line)
    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("")

    $hardware_sim = 0
  end

#  def process_command( cmd )

  it "process command" do

    pin      = rand(9999999).to_i
    value    = rand(9999999).to_i

    command_line = CommandLine.new
    command_line.action       = 'servo move'
    command_line.pin_nr        = pin
    command_line.pin_value_1   = value

    cmd = Command.new
    cmd.command_lines << command_line

    @ramps.ramps_arduino.serial_port.test_serial_read = "R01\nR02\n"

    @controller.process_command( cmd )

    expect(@ramps.ramps_arduino.serial_port.test_serial_write).to eq("F61 P#{pin} V#{value}\n")
  end

#  def process_command( cmd )

  it "process command when command is nil" do
    @controller.process_command( nil )
  end

#  def set_speed(command_line)

end
