# I just use this to test websockets in isolation - feel free to delete it.
require_relative 'lib/status'
require_relative 'lib/messaging/messenger'

Messenger.current.start

puts "UID:   #{Messenger.current.uuid}"
puts "TOKEN: #{Messenger.current.token}"

loop { sleep 0.3 }
