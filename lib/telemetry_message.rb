module FBPi
  # Container object for data to be sent to MeshBlu for logging. This is
  # different than a FBPi::MeshMessage because it is only used for storage of
  # log data, which might not have an intended recipient.
  class TelemetryMessage < Hash

    DEFAULTS = {
       data: "Empty message.",
       name: "log_message",
       priority: "low",
       status: {
          x: -1,
          y: -1,
          z: -1
      }
    }

    def self.build(message, opts = {})
      # This nonsense is for legacy purposes.
      puts message
      DEFAULTS.merge(opts).merge(data: message, time: Time.now.to_i)
    end

    def publish(mesh)
                      # I can uncomment this line when I get sick of
                      # the "nothing to run this cycle" messages.
      mesh.data(self) # unless fetch(:data, '').starts_with?("Nothing")
      self
    end


  end
end
