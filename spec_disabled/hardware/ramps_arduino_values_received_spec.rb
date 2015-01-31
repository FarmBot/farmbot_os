require 'spec_helper'
require './lib/status.rb'
require './lib/database/dbaccess.rb'
require './lib/hardware/gcode/ramps_arduino_values_received.rb'

describe HardwareInterfaceArduinoValuesReceived do

  before do
    $db_write_sync = Mutex.new
    $bot_dbaccess = DbAccess.new('development')
    $dbaccess = $bot_dbaccess
    $dbaccess.disable_log_to_screen()

    $status = Status.new

    @ramps = HardwareInterfaceArduinoValuesReceived.new()

    #@ramps = HardwareInterfaceArduino.new(true)

    #@ramps_param = HardwareInterfaceParam.new
    #@ramps.ramps_param = @ramps_param

  end

  it "load parameters" do

    p  = rand(9999999).to_i
    v  = rand(9999999).to_i

    x  = rand(9999999).to_i
    y  = rand(9999999).to_i
    z  = rand(9999999).to_i

    xa = rand(9999999).to_i
    xb = rand(9999999).to_i
    ya = rand(9999999).to_i
    yb = rand(9999999).to_i
    za = rand(9999999).to_i
    zb = rand(9999999).to_i

    @ramps.load_parameter("P", p)
    @ramps.load_parameter("V", v)
    @ramps.load_parameter("X", x)
    @ramps.load_parameter("Y", y)
    @ramps.load_parameter("Z", z)

    @ramps.load_parameter("XA", xa)
    @ramps.load_parameter("XB", xb)
    @ramps.load_parameter("YA", ya)
    @ramps.load_parameter("YB", yb)
    @ramps.load_parameter("ZA", za)
    @ramps.load_parameter("ZB", zb)

    expect(@ramps.p).to eq(p)
    expect(@ramps.v).to eq(v)

    expect(@ramps.x).to eq(x)
    expect(@ramps.y).to eq(y)
    expect(@ramps.z).to eq(z)

    expect(@ramps.xa).to eq(xa)
    expect(@ramps.xb).to eq(xb)
    expect(@ramps.ya).to eq(ya)
    expect(@ramps.yb).to eq(yb)
    expect(@ramps.za).to eq(za)
    expect(@ramps.zb).to eq(zb)

  end

end

