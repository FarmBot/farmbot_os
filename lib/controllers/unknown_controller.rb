require_relative 'abstract_controller'

module FBPi
  class UnknownController < AbstractController
    def call
      reply "error",
        error: "#{message.method || 'null'} is not a valid `method`."
    end
  end
end
