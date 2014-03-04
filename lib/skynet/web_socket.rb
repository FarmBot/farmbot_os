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
    @socket.on :identify do |data|
      self.emit :identity, {
        uuid:     $skynet.uuid,
        token:    $skynet.token,
        socketid: data['socketid']}
      $skynet.identified = true
    end
  end

  ### Routes all skynet messages to handle_event() for interpretation.
  def create_message_event
    #@socket.on :message do |channel, message|
    #  $skynet.handle_message(channel, message)
    #end
    @socket.on :message do |message|
      $skynet.handle_message(message)
    end
  end

end