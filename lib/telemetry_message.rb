module FBPi
  # Container object for data to be sent to MeshBlu for logging.
  class TelemetryMessage < Hash
    def self.build(message)
      message.is_a?(Hash) ? self.new(message) : from_object(message)
    end

    def self.from_object(m, priority = 'low')
      self.new(log: 'Log Message', priority: priority, data: m)
    end

    def publish(mesh)
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
