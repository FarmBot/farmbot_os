require 'socket.io-client-simple'

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
    # Look ma! Just like in JavaScript!
    this = self
    socket.on :identify do |data|
      auth = {uuid: this.uuid, token: this.token, socketid: data['socketid']}
      emit :identity, auth
    end
  end

  ### Routes all skynet messages to handle_event() for interpretation.
  def create_message_event
    this = self
    socket.on(:message) { |msg| this.handle_message(message) }
  end

end
