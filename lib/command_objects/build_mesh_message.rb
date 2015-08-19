require 'mutations'
require 'securerandom'

module FBPi
  # Builds a message suitable for transmission over MeshBlu messaging system.
  # Message objects are mostly compatible with the JSONRPC protocol, except that
  # they have additional information added to the JSON object related to MeshBlu
  # such as "fromUuid". SEE:
  # https://github.com/octoblu/meshblu     MeshBlu IoT Gateway
  # http://json-rpc.org/wiki/specification JSONRPC v 1.0
  class BuildMeshMessage < Mutations::Command
    required do
      string :fromUuid
      string :method
    end

    optional do
      string :id
      hash(:params, default: {}) { duck :* } # Quack quack!
    end

    def execute
      MeshMessage.new(from:   fromUuid,
                      method: method,
                      params: params || {},
                      id:     id || SecureRandom.uuid)
    end
  end
end
