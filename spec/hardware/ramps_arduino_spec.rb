require 'spec_helper'
require './lib/status.rb'
require './lib/database/dbaccess.rb'
require './lib/hardware/gcode/ramps_arduino.rb'
require './lib/hardware/gcode/ramps_param.rb'

describe HardwareInterfaceArduino do

  before do
    $db_write_sync = Mutex.new
    DbAccess.current = DbAccess.new('development')
    DbAccess.current = DbAccess.current
    DbAccess.current.disable_log_to_screen()

    $status = Status.new

    @ramps = HardwareInterfaceArduino.new(true)

    @ramps_param = HardwareInterfaceParam.new
    @ramps.ramps_param = @ramps_param

  end

  it "read status" do
    @ramps.connect_board
    expect(1).to eq(1)
  end

  it "execute_command"  do

    command = "TEST"

    @ramps.serial_port.test_serial_read = "R01\nR02\n"
    @ramps.execute_command(command, false, false)

    expect(@ramps.serial_port.test_serial_write).to eq("#{command}\n")

  end

  it "execute_command with causing an error"  do

    $status = nil

    @ramps.serial_port.rts = 0
    @ramps.execute_command(nil,nil,nil)

    $status = Status.new

    expect { @ramps }.to_not raise_error

  end

  it "create write status" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = true

    write_status = @ramps.create_write_status(text, log, onscreen)

    expect(write_status.text     ).to eq(text     )
    expect(write_status.log      ).to eq(log      )
    expect(write_status.onscreen ).to eq(onscreen )
  end

  it "handle execution exception" do
    e = Exception.new
    @ramps.handle_execution_exception(e)
    expect(1).to eq(1)
  end

  it "log result of execution" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = true

    write_status = @ramps.create_write_status(text, log, onscreen)

    @ramps.log_result_of_execution(write_status)

    expect(1).to eq(1)
  end

  it "process feedback" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false

    @ramps.serial_port.test_serial_read = "R02\n"

    write_status = @ramps.create_write_status(text, log, onscreen)

    @ramps.process_feedback(write_status)
    @ramps.process_feedback(write_status)
    @ramps.process_feedback(write_status)
    @ramps.process_feedback(write_status)
    @ramps.process_feedback(write_status)

    expect(write_status.done).to eq(1)

  end

  it "and and process characters" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false

    write_status = @ramps.create_write_status(text, log, onscreen)

    @ramps.add_and_process_characters(write_status, 'R')
    @ramps.add_and_process_characters(write_status, '0')
    @ramps.add_and_process_characters(write_status, '2')
    @ramps.add_and_process_characters(write_status, "\n")

    expect(write_status.done).to eq(1)

  end

  it "process codes and parameters R01" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false

    write_status = @ramps.create_write_status(text, log, onscreen)
    write_status.code = "R01"
    timeout = write_status.timeout

    @ramps.process_code_and_params(write_status)

    expect(write_status.timeout).to be > timeout

  end

  it "process codes and parameters R02" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false

    write_status = @ramps.create_write_status(text, log, onscreen)
    write_status.code = "R02"

    @ramps.process_code_and_params(write_status)

    expect(write_status.done).to eq(1)

  end

  it "process codes and parameters R03" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false

    write_status = @ramps.create_write_status(text, log, onscreen)
    write_status.code = "R03"

    @ramps.process_code_and_params(write_status)

    expect(write_status.done).to eq(1)
  end

  it "process codes and parameters R04" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false

    write_status = @ramps.create_write_status(text, log, onscreen)
    write_status.code = "R04"
    timeout = write_status.timeout
    time = Time.now

    @ramps.process_code_and_params(write_status)

    expect(write_status.timeout).to be > timeout
    expect(write_status.start).to be > time

  end

  it "process codes and parameters other" do

    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false
    par      = rand(9999999).to_s

    write_status = @ramps.create_write_status(text, log, onscreen)
    write_status.code = "R83"
    write_status.params = par

    @ramps.process_code_and_params(write_status)

    expect($status.device_version).to eq(write_status.params)

  end


  it "prepare serial port" do
    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false

    write_status = @ramps.create_write_status(text, log, onscreen)

    @ramps.prepare_serial_port(write_status)
    expect(1).to eq(1)
  end

  it "clean serial buffer" do
    @ramps.serial_port.test_serial_read = rand(9999999).to_s
    @ramps.clean_serial_buffer
    expect(@ramps.serial_port.test_serial_read).to eq(nil)

  end

  it "serial port write" do
    text = rand(9999999).to_s
    @ramps.serial_port_write(text)
    expect(@ramps.serial_port.test_serial_write).to eq(text)
  end

  it "emergency stop off" do
    @ramps.serial_port.test_serial_write = ""
    $status.emergency_stop = false
    @ramps.check_emergency_stop
    expect(@ramps.serial_port.test_serial_write).to eq("")
  end

  it "emergency stop on" do
    @ramps.serial_port.test_serial_write = ""
    $status.emergency_stop = true
    @ramps.check_emergency_stop
    expect(@ramps.serial_port.test_serial_write).to eq("E\n")
  end

  it "log incoming text" do
    text     = rand(9999999).to_s
    log      = rand(9999999).to_s
    onscreen = false

    write_status = @ramps.create_write_status(text, log, onscreen)

    @ramps.log_incoming_text(write_status)
    expect(1).to eq(1)
  end

  it "process value split two letters" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R81"
    text = "ZA1 ZB2 XA3 XB4 YA5 YB6"
    @ramps.process_value_split(code, params, text)

    expect(params.za).to eq(1)
    expect(params.zb).to eq(2)
    expect(params.xa).to eq(3)
    expect(params.xb).to eq(4)
    expect(params.ya).to eq(5)
    expect(params.yb).to eq(6)
  end

  it "process value split one letters" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R99"
    text = "P1 V2 X3 Y4 Z5"
    @ramps.process_value_split(code, params, text)

    expect(params.p).to eq(1)
    expect(params.v).to eq(2)
    expect(params.x).to eq(3)
    expect(params.y).to eq(4)
    expect(params.z).to eq(5)

  end

  it "process value R21" do

    param = 1
    value = rand(999).to_i

    code = "R21"
    text = "P#{param} V#{value}"

    params = HardwareInterfaceArduinoValuesReceived.new
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R21(params,code)

    par_obj = @ramps_param.get_param_by_id(param)

    expect(par_obj['value_ar']).to eq(value)

  end

  it "process value R23" do

    param = 1
    value = rand(999).to_i

    code = "R23"
    text = "P#{param} V#{value}"

    params = HardwareInterfaceArduinoValuesReceived.new
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R23(params,code)

    par_obj = @ramps_param.get_param_by_id(param)

    expect(par_obj['value_db']).to eq(value)

  end

  it "process value R41" do

    pinnr = rand(9999999).to_i
    value = rand(9999999).to_i
    exinf = rand(9999999).to_i

    code = "R41"
    text = "P#{pinnr} V#{value}"

    @ramps.external_info = exinf

    params = HardwareInterfaceArduinoValuesReceived.new
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R41(params,code)

    pin_value = 0
    list = DbAccess.current.read_measurement_list()

    list.each do |meas|
      if meas['ext_info'].to_s == exinf.to_s
        pin_value = meas['value']
      end
    end

    expect(pin_value.to_i).to eq(value.to_i)

  end

  it "process value R81 XA" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R81"
    text = " XA1 XB0 YA0 YB0 ZA0 ZB0 "
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R81(params,code)

    expect($status.info_end_stop_x_a).to eq(true)
    expect($status.info_end_stop_x_b).to eq(false)
    expect($status.info_end_stop_y_a).to eq(false)
    expect($status.info_end_stop_y_b).to eq(false)
    expect($status.info_end_stop_z_a).to eq(false)
    expect($status.info_end_stop_z_b).to eq(false)

  end

  it "process value R81 XB" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R81"
    text = " XA0 XB1 YA0 YB0 ZA0 ZB0 "
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R81(params,code)

    expect($status.info_end_stop_x_a).to eq(false)
    expect($status.info_end_stop_x_b).to eq(true)
    expect($status.info_end_stop_y_a).to eq(false)
    expect($status.info_end_stop_y_b).to eq(false)
    expect($status.info_end_stop_z_a).to eq(false)
    expect($status.info_end_stop_z_b).to eq(false)

  end

  it "process value R81 YA" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R81"
    text = " XA0 XB0 YA1 YB0 ZA0 ZB0 "
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R81(params,code)

    expect($status.info_end_stop_x_a).to eq(false)
    expect($status.info_end_stop_x_b).to eq(false)
    expect($status.info_end_stop_y_a).to eq(true)
    expect($status.info_end_stop_y_b).to eq(false)
    expect($status.info_end_stop_z_a).to eq(false)
    expect($status.info_end_stop_z_b).to eq(false)

  end

  it "process value R81 YB" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R81"
    text = " XA0 XB0 YA0 YB1 ZA0 ZB0 "
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R81(params,code)

    expect($status.info_end_stop_x_a).to eq(false)
    expect($status.info_end_stop_x_b).to eq(false)
    expect($status.info_end_stop_y_a).to eq(false)
    expect($status.info_end_stop_y_b).to eq(true)
    expect($status.info_end_stop_z_a).to eq(false)
    expect($status.info_end_stop_z_b).to eq(false)

  end

  it "process value R81 ZA" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R81"
    text = " XA0 XB0 YA0 YB0 ZA1 ZB0 "
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R81(params,code)

    expect($status.info_end_stop_x_a).to eq(false)
    expect($status.info_end_stop_x_b).to eq(false)
    expect($status.info_end_stop_y_a).to eq(false)
    expect($status.info_end_stop_y_b).to eq(false)
    expect($status.info_end_stop_z_a).to eq(true)
    expect($status.info_end_stop_z_b).to eq(false)

  end

  it "process value R81 ZB" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R81"
    text = " XA0 XB0 YA0 YB0 ZA0 ZB1 "
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R81(params,code)

    expect($status.info_end_stop_x_a).to eq(false)
    expect($status.info_end_stop_x_b).to eq(false)
    expect($status.info_end_stop_y_a).to eq(false)
    expect($status.info_end_stop_y_b).to eq(false)
    expect($status.info_end_stop_z_a).to eq(false)
    expect($status.info_end_stop_z_b).to eq(true)

  end

  it "process value R82" do

    x = rand(9999999).to_i
    y = rand(9999999).to_i
    z = rand(9999999).to_i

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R82"
    text = "X#{x} Y#{y} Z#{z}"
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_R82(params,code)

    expect($status.info_current_x_steps).to eq(x)
    expect($status.info_current_y_steps).to eq(y)
    expect($status.info_current_z_steps).to eq(z)

    expect($status.info_current_x      ).to eq(x / @ramps_param.axis_x_steps_per_unit)
    expect($status.info_current_y      ).to eq(y / @ramps_param.axis_y_steps_per_unit)
    expect($status.info_current_z      ).to eq(z / @ramps_param.axis_z_steps_per_unit)

  end

  it "process value R83" do
    code = "R83"
    text = rand(9999999).to_s

    @ramps.process_value_process_R83(code, text)

    expect($status.device_version).to eq(text)
  end


  it "process value R99" do

    code = "R99"
    text = rand(9999999).to_s

    @ramps.process_value_process_R99(code, text)
  end

  it "save pin value" do

    pinnr = rand(9999999).to_i
    value = rand(9999999).to_i
    exinf = rand(9999999).to_i

    @ramps.external_info = exinf
    @ramps.save_pin_value(pinnr, value)

    pin_value = 0
    list = DbAccess.current.read_measurement_list()

    list.each do |meas|
      if meas['ext_info'].to_s == exinf.to_s
        pin_value = meas['value']
      end
    end

    expect(pin_value.to_i).to eq(value.to_i)
  end

  it "process value process param list 1" do

    # "process value R21"

    param = 1
    value = rand(999).to_i

    code = "R21"
    text = "P#{param} V#{value}"

    params = HardwareInterfaceArduinoValuesReceived.new
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_process_param_list(params,code)

    par_obj = @ramps_param.get_param_by_id(param)

    expect(par_obj['value_ar']).to eq(value)
  end

  it "process value process param list 2" do

    # "process value R23"

    param = 1
    value = rand(999).to_i

    code = "R23"
    text = "P#{param} V#{value}"

    params = HardwareInterfaceArduinoValuesReceived.new
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_process_param_list(params,code)

    par_obj = @ramps_param.get_param_by_id(param)

    expect(par_obj['value_db']).to eq(value)

  end

  it "process value process param list 3" do

    # "process value R41"

    pinnr = rand(9999999).to_i
    value = rand(9999999).to_i
    exinf = rand(9999999).to_i

    code = "R41"
    text = "P#{pinnr} V#{value}"

    @ramps.external_info = exinf

    params = HardwareInterfaceArduinoValuesReceived.new
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_process_param_list(params,code)

    pin_value = 0
    list = DbAccess.current.read_measurement_list()

    list.each do |meas|
      if meas['ext_info'].to_s == exinf.to_s
        pin_value = meas['value']
      end
    end

  end

  it "process value process text 1" do

    # process_value_process_R83

    code = "R83"
    text = rand(9999999).to_s

    @ramps.process_value_process_R83(code, text)

    expect($status.device_version).to eq(text)

  end

  it "process value process text 2" do

    # process_value_process_R99

    code = "R99"
    text = rand(9999999).to_s

    @ramps.process_value_process_R99(code, text)

  end

  it "process value 1" do

    # "process value R21"

    param = 1
    value = rand(999).to_i

    code = "R21"
    text = "P#{param} V#{value}"

    @ramps.process_value(code,text)

    par_obj = @ramps_param.get_param_by_id(param)

    expect(par_obj['value_ar']).to eq(value)

  end

  it "process value 2" do


    # process_value_process_R99

    code = "R99"
    text = rand(9999999).to_s

    @ramps.process_value(code,text)

  end

  it "process value 3" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R81"
    text = " XA0 XB0 YA0 YB0 ZA0 ZB1 "
    @ramps.process_value(code,text)

    expect($status.info_end_stop_x_a).to eq(false)
    expect($status.info_end_stop_x_b).to eq(false)
    expect($status.info_end_stop_y_a).to eq(false)
    expect($status.info_end_stop_y_b).to eq(false)
    expect($status.info_end_stop_z_a).to eq(false)
    expect($status.info_end_stop_z_b).to eq(true)

  end

  it "process value named parameters 1" do

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R81"
    text = " XA0 XB0 YA0 YB0 ZA0 ZB1 "
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_process_named_params(params,code)

    expect($status.info_end_stop_x_a).to eq(false)
    expect($status.info_end_stop_x_b).to eq(false)
    expect($status.info_end_stop_y_a).to eq(false)
    expect($status.info_end_stop_y_b).to eq(false)
    expect($status.info_end_stop_z_a).to eq(false)
    expect($status.info_end_stop_z_b).to eq(true)

  end

  it "process value named parameters 2" do

    x = rand(9999999).to_i
    y = rand(9999999).to_i
    z = rand(9999999).to_i

    params = HardwareInterfaceArduinoValuesReceived.new
    code = "R82"
    text = "X#{x} Y#{y} Z#{z}"
    @ramps.process_value_split(code, params, text)
    @ramps.process_value_process_named_params(params,code)

    expect($status.info_current_x_steps).to eq(x)
    expect($status.info_current_y_steps).to eq(y)
    expect($status.info_current_z_steps).to eq(z)

    expect($status.info_current_x      ).to eq(x / @ramps_param.axis_x_steps_per_unit)
    expect($status.info_current_y      ).to eq(y / @ramps_param.axis_y_steps_per_unit)
    expect($status.info_current_z      ).to eq(z / @ramps_param.axis_z_steps_per_unit)

  end

end

