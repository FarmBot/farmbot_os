# FarmBot Controller

require_relative 'settings.rb'

system('clear')
puts ''

puts '    /\    '
puts '----------'
puts ' FarmTalk '
puts '----------'
puts '    \/    '
puts ''

require_relative 'lib/status'
$status = Status.new

$shutdown = 0
$db_write_sync = Mutex.new

print 'database        '
require 'active_record'
require_relative 'lib/database/dbaccess'
puts 'OK'

print 'synchronization '
require_relative 'lib/messaging'
puts 'OK'

puts "uuid            #{Messaging.current.uuid}"
puts "token           #{Messaging.current.token}"

puts 'press key to stop'
gets.chomp

