require_relative 'abstract_controller'

class ReadStatusController < AbstractController
  def call
    reply "status", error: "#{message.type} is not a valid message_type."
  end
end
