# FarmBot Controller

require_relative 'settings.rb'

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

if $hardware_type != nil
  puts "connecting to hardware: #{$hardware_type}"
  require_relative 'lib/controller'
  require_relative $hardware_type
  $bot_hardware = HardwareInterface.new
else
  $hardware_sim = 1
end

if $controller_disable == 0
  puts 'starting controller'
  require_relative 'lib/controller'
  $bot_control  = Controller.new
  $bot_control.runFarmBot
else
  puts 'press key to stop'
  gets.chomp
end
