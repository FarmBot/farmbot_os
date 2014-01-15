# FarmBot Controller runtime control

# Get commands from the database and execute them on the hardware

puts '[FarmBot Controller]'
puts 'starting up'

require 'date'

require './lib/dbaccess.rb'
require './lib/controller.rb'
require './lib/filehandler.rb'
require "./lib/hardware/ramps.rb"
require './lib/schedule.rb'

puts 'connecting to hardware'

#$bot_control  = Control.new
#$bot_hardware = HardwareInterface.new

puts 'connecting to database'

$bot_dbaccess = DbAccess.new
$bot_schedule = Scheduler.new

$shutdown = 0

# controller loop

puts 'run'

$bot_schedule.runFarmBot
