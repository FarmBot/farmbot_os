require_relative 'abstract_controller'
require_relative '../command_objects/commands'

class SyncSequenceController < AbstractController
  def call
    @schedule_list = Array(@message.payload["command"])

    ActiveRecord::Base.transaction do
      Schedule.destroy_all
      @schedule_list.map { |s| CreateSchedule.run!(s) }
    end

    reply "sync_sequence"
  rescue Mutations::ValidationException => error
    reply "error", error: error.message
  end
end
