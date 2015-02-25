
# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerMessage

  attr_accessor :sender, :time_stamp, :message_type, :payload
  attr_accessor :handled, :handler, :delay

  def initialize
    handled = false
  end

  def handle_message(message)
    message.handled = true
    puts 'This is probably where the message gets handled.'
  end

end
