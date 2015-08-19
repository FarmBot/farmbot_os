require_relative 'abstract_controller'
require_relative '../command_objects/report_bot_status'
module FBPi
  # Responsible for reporting the status of the Bot when it is requested by a
  # user
  class ReadStatusController < AbstractController
    def call
      reply "read_status", ReportBotStatus.run!(bot: bot)
    end
  end
end
