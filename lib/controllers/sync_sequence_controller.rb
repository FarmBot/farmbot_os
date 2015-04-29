require_relative 'abstract_controller'
require_relative '../sequences/sequences'

class SyncSequenceController < AbstractController
  def call
    schedule_list = Array(@message.payload["command"])
    schedule_list.map! { |s| ScheduleFactory.run!(s) }
    reply "sync_sequence"
  rescue Mutations::ValidationException => error
    reply "error", error: error.message
  end
end
