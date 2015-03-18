# A data transfer object. Deserializes incoming JSON into a Ruby object.
class MessageHandlerMessage

  attr_accessor :sender, :time_stamp, :message_type, :payload, :handled,
                :handler, :delay

  def initialize(message, handler)
    @handler = handler
    set_fields_from_hash(message)
  end

  # Move the data from the hash into to object
  def set_fields_from_hash(message)
    @sender       = message['fromUuid'] || ''
    @payload      = message['payload'] || {}
    @message_type = payload['message_type'].to_s.downcase  || ''
    @time_stamp   = payload['time_stamp'] || nil
    @handled      = false
  end

end
