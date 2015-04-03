class MeshMessage
  attr_reader :from, :type, :time, :payload

  def initialize(from:, type:, time:, payload:)
    @from, @type, @payload, @time = from, type, payload, Time.parse(time.to_s)
  end
end
