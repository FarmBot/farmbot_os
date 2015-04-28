## SERIAL PORT SIMULATION
## **********************
class FakeSerialPort < StringIO
  def initialize(*)
    super("")
  end

  def message
    rewind
    read.chomp
  end
end
