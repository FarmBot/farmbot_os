# FarmBot Controller
require 'pry'
require_relative 'settings.rb'

system('clear')
puts ''

puts '   /\    '
puts '---------'
puts ' FarmBot '
puts '---------'
puts '   \/    '
puts '========='

require_relative 'lib/status'
Status.current = Status.new

$shutdown = 0
$db_write_sync = Mutex.new

print 'database        '
require 'active_record'
require_relative 'lib/database/dbaccess'
puts 'OK'

print 'synchronization '
require_relative 'lib/messaging/messenger'
Messenger.current.start
puts 'OK'

if $hardware_type != nil
  puts  "hardware        #{$hardware_type}"
  print 'hardware        '
  require_relative 'lib/controller'
  require_relative $hardware_type
  HardwareInterface.current = HardwareInterface.new(false)
else
  $hardware_sim = 1
end
puts 'OK'

puts "uuid            #{Messenger.current.uuid}"
puts "token           #{Messenger.current.token}"
if $controller_disable == 0
  print 'controller      '
  require_relative 'lib/controller'
  $bot_control  = Controller.new
  $bot_control.runFarmBot
else
  puts 'press key to stop'
  gets.chomp
end
