require 'json'
require './lib/database/dbaccess.rb'
require 'time'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerBase

  attr_accessor :message
  attr_accessor :messaging

  ## general handling messages

  def initialize(messaging)
    @messaging = messaging
    @dbaccess = DbAccess.current
    @last_time_stamp  = ''
  end

  # A list of MessageHandler methods (as strings) that a Skynet User may access.
  #
  def whitelist
    ['test']
  end

  # Handle the message received from skynet
  #
  def handle_message(message)

    if whitelist.include?(message.message_type)
      self.send(message.message_type,message)
      message.handled = true
    end

  end

  def test(message)
  end

end
