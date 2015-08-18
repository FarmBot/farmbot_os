require_relative "fake_socket"

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

    def method
      results[:method] || 'not_specified'
    end

    def results
      (@params[:result] || @params[:error] || {})
    end
  end

  def emit(name, params)
    @last = @all.push(Emission.new(name, params)).last
  end

  def data(hash)
    emit('telemetry', hash)
  end

  def socket
    @socket ||= FakeSocket.new('123', 'abc')
  end
end
