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
    yield(body, request, response)
  end
end

class Rest
  def self.get(url, headers)
    i = self.new(nil, nil, nil)
    RestClient.get(url, headers) do |a, b, c|
      i.body, i.request, i.response = a, b, c
      i.run
    end
  rescue => e
    BadHttpResp.new(e, e, e) # ?
  end

  attr_accessor :body, :request, :response

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

SCHEDULE_URL = 'http://localhost:3000/api/schedules/'
SEQUENCE_URL = 'http://localhost:3000/api/sequences/'
CREDS = {
  bot_uuid:  "1b6d9043-8949-4199-b13e-58ae6e2ea181",
  bot_token: "229458c0a7044b5ceca92e9257ac32156baa63c2",
}
# /api/sequences/:sequence_id/steps
class SequenceFetchError; end

def get_steps(schedules)
  schedules
    .map { |sd| "#{SEQUENCE_URL}#{sd["sequence_id"]}/steps" }
    .map { |url| Rest.get(url, CREDS).no{raise SequenceFetchError} }
    .map { |res| res.obj }
    .each_with_index
    .map { |s, i| schedules[i]["steps"] = s; schedules[i] }
rescue SequenceFetchError => e
  binding.pry
end

def get_schedules
  Rest
  .get(SCHEDULE_URL, CREDS)
  .no { |error| puts error }
  .ok { |a,b,c| get_steps(a) }
end
binding.pry
get_schedules

puts '?'
