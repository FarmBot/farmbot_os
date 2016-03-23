module FBPi
  # Represents a message as it enters the bot from the outside world. Mostly
  # compliant with JSONRPC specification, with the exception being that some
  # extra, non-JSONRPC compliant fields were added to store MeshBlu specific
  # info, such as fromUuid.
  # http://json-rpc.org/wiki/specification
  class MeshMessage
    attr_accessor :method, :params, :id

    def initialize(method:, params: {}, id: '')
      @method, @params, @id = method, params, id
    end
  end
end
