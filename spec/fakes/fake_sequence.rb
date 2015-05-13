require_relative "fake_step"

class FakeSequence
  attr_reader :steps, :name

  def initialize
    @steps, @name = [FakeStep.new, FakeStep.new], "Fake"
  end
end
