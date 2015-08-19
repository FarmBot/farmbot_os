require_relative 'abstract_controller'

module FBPi
  # Just a controller that gets called when a user tries to access a nonexistant
  # controller name.
  class UnknownController < AbstractController
    def call
      reply "error",
        error: "#{message.method || 'null'} is not a valid `method`."
    end
  end
end
