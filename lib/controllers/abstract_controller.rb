class AbstractController
  attr_reader :message, :bot, :mesh

  def initialize(message, bot, mesh)
    @message, @bot, @mesh = message, bot, mesh
  end
end
