require 'mutations'
require 'securerandom'

module FBPi
  # This class emits a JSONRPC compliant response object using a provided mesh
  # object.
  # For more info see: http://json-rpc.org/wiki/specification#a1.2Response
  class SendMeshResponse < Mutations::Command
    required do
      duck :message, methods: [:id, :from]
      duck :mesh, methods: [:emit]
      string :method
    end

    optional do
      hash(:result, default: {}) do
        duck :*, methods: [:to_json]
      end
    end

    def execute
      mesh.emit message.from, output
    end

    def output
      hsh = {id: message.id, error: nil, result: nil}
      hsh[(method == "error") ? :error : :result] = result.merge(method: method)
      hsh.deep_symbolize_keys # :(
    end
  end
end
