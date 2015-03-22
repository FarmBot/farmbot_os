# test

require 'json'
#require_relative 'messagehandler.rb'

class StubMessenger

  attr_accessor :message
  attr_accessor :device

  def initialize
    reset()
  end

  def reset
    @device = ''
    @message = {}
  end

  def send_message(devices, message_hash )
    @message = message_hash
    @device = devices
  end

end
