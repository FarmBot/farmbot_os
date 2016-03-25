
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
      duck :message, methods: [:payload, :symbolize_keys, :[], :[]=]
    end

     def validate
       parse_message
       type_check "params", Hash
       type_check "method", String
       message["id"] ||= SecureRandom.uuid # Just incase...
     end

    def execute
      MeshMessage.new(message.symbolize_keys)
    end

    private

    def parse_message
      inputs["message"] = JSON.parse(inputs["message"].payload)
    rescue JSON::ParserError => e
      add_error :payload, :parse_error, "Message was probably not JSON"
    end

    def type_check(key, klass)
      if (message[key].is_a?(klass))
        return true
      else
        add_error :payload, :key, "Expected #{key} to be a #{klass}"
        return false
      end
    end
  end
end
