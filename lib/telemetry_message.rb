module FBPi
  # Container object for data to be sent to MeshBlu for logging.
  class TelemetryMessage < Hash
    def self.build(message)
      message.is_a?(Hash) ? self.new(message) : from_object(message)
    end

    # If message isn't a hash (numeric, string, etc), wrap it in some keys.
    def self.from_object(m, priority = 'low')
      self.new(log: 'Log Message', priority: priority, data: m)
    end

    def publish(mesh)
      # I was getting sick of seeing those "Nothing to run this cycle" msgs in
      # the telemetry logs, so I squelched them out here. PRs welcome.
      mesh.data(self) unless fetch(:data, '').starts_with?("Nothing")
      self
    end

    def initialize(**kwargs)
      self
        .merge!(priority: 'low', name: "Log Message")
        .merge!(kwargs)
    end
  end
end
