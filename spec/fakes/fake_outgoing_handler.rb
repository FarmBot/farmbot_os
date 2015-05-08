class FakeOutgoingHandler
  attr_accessor :logs
  def initialize
    @logs = []
  end

  def method_missing(sym, *args, &block)
    logs.push({sym => args})
  end

  def last
    logs.last
  end
end
