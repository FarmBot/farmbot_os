require 'mutations'
require 'securerandom'

module FBPi
  # Occasionally, the bot will receive trash messages that are not formatted in
  # a coherent manner. This object will attempt to recover from failure by
  # building an error response and avoiding a crash or unsafe behavior. This
  # object operates in a very uncertain environment, so approach with caution.
  class DisposeTrashMessage < Mutations::Command
    # Nothing is certain, so all inputs are optional with safe defaults.
    optional do
      duck :id
      duck :params
      duck :fromUuid
      duck :method
    end

    def execute
      be_careful(id,       String, :to_s, SecureRandom.uuid)
      be_careful(method,   String, :to_s, 'unknown')
      be_careful(fromUuid, String, :to_s, '---')
      be_careful(params,   Hash,   :to_h, {})

      MeshMessage.new(from:   fromUuid,
                      method: method,
                      params: params,
                      id:     id)
    end

  private

    # The most cowardly of all methods. Coerces an object to a class, or cowers
    # in fear of the consequences.
    def be_careful(object, klass, coersion, default)
      object.send(coersion) if object.respond_to?(coersion) # Attempt coercion
      object.is_a?(klass) ? object : default # Return coerced value or default.
    end
  end
end
