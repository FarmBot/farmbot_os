require 'socket.io-client-simple'
#require_relative 'socket.io-client-simple.rb'

module WebSocket
  ### Bootstraps all the events for skynet in the correct order. Returns Int.
  def create_socket_events
    #OTHER EVENTS: :identify, :identity, :ready, :disconnect, :message

    create_identify_event
    create_message_event
  end

  #Handles self identification on skynet by responding to the :indentify with a
  #:identity event / credentials Hash.
  def create_identify_event
    socket.on :identify do |data|
      auth_data = {uuid: uuid, token: token, socketid: data['socketid']}
      socket.emit :identity, auth_data
      identified = true
    end
  end

  ### Routes all skynet messages to handle_event() for interpretation.
  def create_message_event
    socket.on(:message) { |message| Messaging.current.handle_message(message) }
  end

end
