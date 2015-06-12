class AbstractResp
  attr_reader :body, :request, :response

  def initialize(body, request, response)
    @body, @request, @response = body, request, response
  end

  def obj
    JSON.parse(body.to_s)
  rescue JSON::ParserError
    body
  end

  def ok; self; end
  def no; self; end
end
