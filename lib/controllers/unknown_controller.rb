require_relative 'abstract_controller'

module FBPi
  class UnknownController < AbstractController
    def call
      reply "error", error: "#{message.method} is not a valid message_type."
    end
  end
end
