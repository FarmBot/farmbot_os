require 'json'
require_relative 'credentials'
require_relative 'web_socket'
require_relative '../handlers/messagehandler.rb'

# Communicates with MeshBlu via websocket connection.
class Messenger
  class << self
    attr_accessor :current

    def current
      @current ||= self.new
    end
  end

  attr_accessor :socket, :uuid, :token, :message_handler

  include Credentials, WebSocket

  # On instantiation #new sets the @uuid, @token variables, connects to skynet
  def initialize
    creds      = credentials
    @uuid      = creds[:uuid]
    @token     = creds[:token]
    @socket   = SocketIO::Client::Simple.connect 'wss://meshblu.octoblu.com:443'
  end

  def start(handler = MessageHandler.new(self))
    @message_handler  = handler
    create_socket_events
  end

  def send_message(devices, message_hash )
    @socket.emit("message", devices: devices, message: message_hash)
  end

  # Acts as the entry point for message traffic captured from MeshBlu.
  def handle_message(message)
    case message
    when Hash
      message_handler.handle_message(message)
    when String
      message_hash = JSON.parse(message)
      message_handler.handle_message(message_hash)
    else
      "Can't handle messages of class #{message.class}"
    end
  rescue
    raise "Runtime error while attempting to parse message: #{message}."
  end

end
