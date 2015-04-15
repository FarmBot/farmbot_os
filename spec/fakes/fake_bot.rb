class FakeBot
  attr_reader :logs, :last_log

  def initialize
    @logs = []
  end

  def log(msg)
    @last_log = @logs.push(msg).last
  end
end
