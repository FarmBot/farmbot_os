class FakeMesh
  attr_reader :last, :all
  def initialize
    @all = []
  end

  # Holds data that was emitted.
  class Emission
    attr_reader :name, :params
    def initialize(name, params)
      @name, @params = name, params
    end

    def type
      (@params[:result] || @params[:error] || {})[:type] or
      raise "Make sure that mesh messages have either a 'result' or 'error' key"
    end
  end

  def emit(name, params)
    @last = @all.push(Emission.new(name, params)).last
  end

  def data(hash)
    emit('telemetry', hash)
  end
end
