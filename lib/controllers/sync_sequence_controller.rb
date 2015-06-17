require_relative 'abstract_controller'
require 'farmbot-resource'
require_relative '../command_objects/commands'

module FBPi
  class SyncSequenceController < AbstractController
    def call
      api = bot.rest_client
      ActiveRecord::Base.transaction do
        JoinSequenceSchedules
          .run!(schedules: api.schedules.fetch,
                sequences: api.sequences.fetch)
          .tap { Schedule.destroy_all }
          .map { |s| CreateSchedule.run!(s) }
      end

      reply "sync_sequence"
    rescue FbResource::FetchError => error
      reply "error", error: error.message, hint: "The Webapp is having issues"
    end
  end
end
