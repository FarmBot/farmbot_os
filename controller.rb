# FarmBot Controller runtime control

# Get commands from the database and execute them on the hardware

puts '[FarmBot Controller]'
puts 'starting up'

puts 'connecting to hardware'

require_relative 'lib/controller'

#require_relative "lib/hardware/firmata/ramps"
require_relative "lib/hardware/gcode/ramps"

$bot_control  = Controller.new
$bot_hardware = HardwareInterface.new

$shutdown = 0

puts 'starting farmbot'
$bot_control.runFarmBot
