require 'mutations'
require 'securerandom'

module FBPi
  # This class emits a JSONRPC compliant response object using a provided mesh
  # object.
  # For more info see: http://json-rpc.org/wiki/specification#a1.2Response
  class SendMeshResponse < Mutations::Command
    required do
      duck :original_message, methods: [:id]
      duck :mesh, methods: [:emit]
      string :method
    end

    optional do
      hash(:result, default: {}) do
        duck :*, methods: [:to_json]
      end
    end

    def execute
      mesh.emit "bot/CHANGE_THIS_PLEASE", output
    end

    def output
      hsh = {id: original_message.id, error: nil, result: nil}
      key = (method == "error") ? :error : :result
      hsh[key] = result.merge(method: method)
      hsh.deep_symbolize_keys # :(
    end
  end
end
