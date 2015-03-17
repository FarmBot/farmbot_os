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

  attr_accessor :socket, :uuid, :token, :identified, :confirmed,
    :confirmation_id

  include Credentials, WebSocket

  # On instantiation #new sets the @uuid, @token variables, connects to skynet
  def initialize
    identified = false
    creds      = credentials
    @uuid      = creds[:uuid]
    @token     = creds[:token]
    # Still pointing to old URL?
    @socket    = SocketIO::Client::Simple.connect 'http://skynet.im:80'
    @confirmed = false
  end

  def start
    create_socket_events
    @message_handler  = MessageHandler.new(self)
  end

  def send_message(devices, message_hash )
    @socket.emit("message", devices: devices, message: message_hash)
  end

  # Acts as the entry point for message traffic captured from MeshBlu.
  def handle_message(message)
    case message
    when Hash
      @message_handler.handle_message(message)
    when String
      message_hash = JSON.parse(message)
      @message_handler.handle_message(message_hash)
    else
      raise "Can't handle messages of class #{message.class}"
    end
  rescue
    raise "Runtime error while attempting to parse message: #{message}."
  end

end
