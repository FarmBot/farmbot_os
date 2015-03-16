require 'spec_helper'
require './lib/status.rb'
require './lib/database/dbaccess.rb'
require './lib/hardware/gcode/ramps_arduino_write_status.rb'

describe HardwareInterfaceArduinoWriteStatus do

  before do
    $db_write_sync = Mutex.new
    DbAccess.current = DbAccess.new('development')
    DbAccess.current = DbAccess.current
    DbAccess.current.disable_log_to_screen()

    Status.current = Status.new

    @ramps = HardwareInterfaceArduinoWriteStatus.new()

  end

  it "is busy 1" do

    @ramps.done = 0
    busy = @ramps.is_busy
    expect(busy).to eq(true)

  end

  it "is busy 2" do

    @ramps.done = 1
    busy = @ramps.is_busy
    expect(busy).to eq(false)

  end

  it "split parameter" do

    @ramps.received = "R00 XXX"
    @ramps.split_received()

    expect(@ramps.code).to eq("R00")
    expect(@ramps.params).to eq("XXX")

  end

end
