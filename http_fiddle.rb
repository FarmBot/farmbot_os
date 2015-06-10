require 'rest-client'
require 'json'
require 'pry'

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

class GoodHttpResp < AbstractResp
  def ok
    yield(obj, request, response)
  end
end

class BadHttpResp < AbstractResp
  def no
    yield body, request, response
  end
end

class Rest
  def self.get(url, headers)
    RestClient.get(URL, CREDS) { |a, b, c| self.new(a,b,c).run }
  end

  attr_reader :body, :request, :response

  def initialize(body, request, response)
    @body, @request, @response = body, request, response
  end

  def run
    (success? ? GoodHttpResp : BadHttpResp).new(body, request, response)
  end

  def success?
    response.code[0].to_i == 2
  end
end

URL   = 'http://localhost:3000/api/schedules'
CREDS = {
  bot_uuid:  "1b6d9043-8949-4199-b13e-58ae6e2ea181",
  bot_token: "229458c0a7044b5ceca92e9257ac32156baa63c2",
}

def get_steps
end

def get_sequences
end

def get_schedules
  Rest
  .get(URL, CREDS)
  .ok { |a,b,c| binding.pry }
  .no { |a,b,c| binding.pry }
end

