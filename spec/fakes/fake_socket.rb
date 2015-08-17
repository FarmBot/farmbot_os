class FakeSocket
  attr_reader :uuid, :token, :events

  def initialize(uuid, token)
    @uuid, @token, @events = uuid, token, Hash.new([])
  end

  def on(name, &blk)
    events[name] ||= []
    events[name].push(blk)
    events
  end
end
