class FakeMesh
  attr_reader :last, :all
  def initialize
    @all = []
  end

  # Holds data that was emitted.
  class Emission
    attr_reader :name, :payload
    def initialize(name, payload)
      @name, @payload = name, payload
    end

    def type
      @payload[:message_type] || "not set"
    end
  end

  def emit(name, payload)
    @last = @all.push(Emission.new(name, payload)).last
  end

  def data(hash)
    emit('telemetry', hash)
  end
end
