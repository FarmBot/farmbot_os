# test

require 'json'
#require_relative 'messagehandler.rb'

class MessagingTest

  attr_accessor :message
  attr_accessor :device

  def initialize
    reset()
  end

  def reset
    @device = ''
    @message = ''
  end

  def send_message(devices, message_hash )
    @message = message_hash
    @devices = devices
  end

end
