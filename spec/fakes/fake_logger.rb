class FakeLogger < StringIO
  def initialize(input = "")
    super
  end

  def message
    rewind
    read.chomp
  end
end
