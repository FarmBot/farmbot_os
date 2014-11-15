require 'json'
require './lib/database/dbaccess.rb'
require 'time'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerEmergencyStop

  attr_accessor :message

  ## general handling messages

  def initialize
    @dbaccess = DbAccess.new
    @last_time_stamp  = ''
  end

  # A list of MessageHandler methods (as strings) that a Skynet User may access.
  #
  def whitelist
    ["emergency_stop","emergency_stop_reset"]
  end

  # Handle the message received from skynet
  #
  def handle_message(message)

    handled = false

    if whitelist.include?(message.message_type)
      self.send(message)
      handled = true
    end

    handled
  end

  ## emergency stop

  # emergency stop activate
  #
  def emergency_stop(message)

    @dbaccess.write_to_log(2,'handle emergency stop')

    $status.emergency_stop = true
    message.hander.send_confirmation(message.sender, message.time_stamp)
  end

  # emergency stop activate
  #
  def emergency_stop_reset(message)

    @dbaccess.write_to_log(2,'handle emergency stop reset')

    $status.emergency_stop = false
    message.hander.send_confirmation(message.sender, message.time_stamp)
    message.handler.send_confirmation(message.sender, message.time_stamp)
  end

end
