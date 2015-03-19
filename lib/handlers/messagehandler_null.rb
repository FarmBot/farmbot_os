require 'json'
require './lib/database/dbaccess.rb'
require 'time'
require_relative 'messagehandler_base'
require_relative 'messagehandler_schedule_cmd_line'
# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerNull < MessageHandlerBase

  attr_accessor :message

  def handle_message(message)
    are_you_lost?(message)
  end

  def are_you_lost?(message)
    raise "We could not find that route."
  rescue => e
    message.handler.send_error(message.sender, e)
  end

end
