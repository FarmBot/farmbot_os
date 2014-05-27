# FarmBot Controller

system('clear')
puts ''

puts '   /\    '
puts '---------'
puts ' FarmBot '
puts '---------'
puts '   \/    '
puts ''

$shutdown = 0

puts 'connecting to database'
require 'active_record'
require_relative 'lib/database/dbaccess'

$bot_dbaccess = DbAccess.new

puts 'starting synchronization'
require_relative 'lib/skynet'

puts 'connecting to hardware'
require_relative 'lib/controller'
#require_relative "lib/hardware/firmata/ramps"
require_relative "lib/hardware/gcode/ramps"
$bot_hardware = HardwareInterface.new

puts 'connecting to hardware'
$bot_control  = Controller.new
$bot_control.runFarmBot
