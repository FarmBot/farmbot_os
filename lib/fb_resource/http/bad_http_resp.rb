class BadHttpResp < AbstractResp
  def no
    yield(body, request, response)
  end
end
