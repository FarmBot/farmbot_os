class GoodHttpResp < AbstractResp
  def ok
    yield(obj, request, response)
  end
end
