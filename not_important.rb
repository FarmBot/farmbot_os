require_relative 'lib/messaging/messenger'
Messenger.current.start

# require 'io/console'
# loop do
#   case STDIN.getch.downcase
#   when 'r'
#     puts 'Reloading...'
#     load './lib/messaging/messenger.rb'
#     Messenger.current = Messenger.new
#     puts 'Restarting websocket'
#     Messenger.current.start
#     puts 'Done reloading.'
#   when 'q'
#     exit
#   else
#     puts 'Try typing r instead'
#   end
# end

loop { sleep 0.3 }
