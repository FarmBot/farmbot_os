require 'json'
require './lib/database/dbaccess.rb'
require 'time'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerBase

  attr_accessor :message

  ## general handling messages

  def initialize
    @dbaccess = $bot_dbaccess
    @last_time_stamp  = ''
  end

  # A list of MessageHandler methods (as strings) that a Skynet User may access.
  #
  def whitelist
    []
  end

  # Handle the message received from skynet
  #
  def handle_message(message)

    handled = false

    if whitelist.include?(message.message_type)
      self.send(message.message_type,message)
      handled = true
    end

    handled
  end

end
