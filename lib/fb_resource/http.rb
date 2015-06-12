require_relative 'http/abstract_resp'
require_relative 'http/bad_http_resp'
require_relative 'http/good_http_resp'

module FbResource
  class Http
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
end
