module FBPi
  class TelemetryMessage < Hash
    def self.build(message)
      message.is_a?(Hash) ? self.new(kwargs) : from_object(message)
    end

    def self.from_object(m, priority = 'low')
      self.new(log: 'Log Message', priority: priority, data: m)
    end

    def self.publish(m, mesh)
      mesh.data(m) if @last_msg != m # Might not filter obj w/ time stamp
      @last_msg = m
    end

    def publish(mesh)
      self.class.publish(self, mesh) && self
    end

    def initialize(**kwargs)
      self
        .merge!({priority: 'low', name: "Log Message"})
        .merge!(kwargs)
    end

    def priority
      self[:priority]
    end

    def name
      self[:name]
    end
  end
end
