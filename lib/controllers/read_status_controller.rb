require_relative 'abstract_controller'
require_relative '../command_objects/fetch_bot_status'
module FBPi
  class ReadStatusController < AbstractController
    def call
      reply "read_status", FetchBotStatus.run!(bot: bot)
    end
  end
end
