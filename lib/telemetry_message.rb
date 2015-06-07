module FBPi
  # Container object for data to be sent to MeshBlu for logging.
  class TelemetryMessage < Hash
    def self.build(message)
      message.is_a?(Hash) ? self.new(kwargs) : from_object(message)
    end

    def self.from_object(m, priority = 'low')
      self.new(log: 'Log Message', priority: priority, data: m)
    end

    # Pushes a message to the mesh server. Won't publish the same message twice.
    def self.publish(m, mesh)
      mesh.data(m) if @last_msg != m # Might not filter obj w/ time stamp
      @last_msg = m
    end

    def publish(mesh)
      self.class.publish(self, mesh) && self
    end

    def initialize(**kwargs)
      self
        .merge!(priority: 'low', name: "Log Message")
        .merge!(kwargs)
    end
  end
end
