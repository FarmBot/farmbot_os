class FakeStep
  attr_reader :bot

  def execute(bot)
    @executed, @bot = true, bot
  end

  def called?
    @executed
  end
end
