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
Status.current = Status.new

$shutdown = 0
$db_write_sync = Mutex.new

print 'database        '
require 'active_record'
require_relative 'lib/database/dbaccess'
puts 'OK'

print 'synchronization '
require_relative 'lib/messaging'
puts 'OK'

puts "uuid            #{Messenger.current.uuid}"
puts "token           #{Messenger.current.token}"

puts 'press key to stop'
gets.chomp

