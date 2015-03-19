require 'json'
require './lib/database/dbaccess.rb'
require 'time'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerBase
  attr_accessor :message, :messaging

  WHITELIST = ['test']

  ## general handling messages
  def initialize(messaging)
    @messaging = messaging
    @dbaccess = DbAccess.current
    @last_time_stamp  = ''
  end

  # Handle the message received from skynet
  #
  def handle_message(message)
    if WHITELIST.include?(message.message_type)
      self.send(message.message_type, message)
    else
      # TODO Make sure that this exception travels up the stack to send_error in
      # some tests.
      raise 'Nope.'
    end
  end

  def test(*)
    "? What is this ?"
  end
end
