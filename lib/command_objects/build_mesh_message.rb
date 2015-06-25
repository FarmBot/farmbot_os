require 'mutations'
require 'securerandom'

module FBPi
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
