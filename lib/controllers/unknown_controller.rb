require_relative 'abstract_controller'

module FBPi
  # Just a controller that gets called when a user tries to access a nonexistant
  # controller name.
  class UnknownController < AbstractController
    def call
      really_long_message = "You tried to send a message with a `method` " +
                            "property of `#{message.method || 'null'}`, but " +
                            "that's not a valid options."
      reply "error", error: really_long_message
    end
  end
end
