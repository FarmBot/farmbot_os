module FBPi
  # This Object is responsible for contacting the Farmbot Web App via REST calls
  # in order to fetch the latest command execution schedules.
  class SyncBot < Mutations::Command
    required { duck :bot, methods: [:rest_client] }

    def execute
      api = bot.rest_client
      ActiveRecord::Base.transaction do
       [Schedule, Sequence, Step].map(&:destroy_all)
       {sequences: api.sequences.fetch.map { |s| CreateSequence.run!(s) }.count,
        schedules: api.schedules.fetch.map { |s| CreateSchedule.run!(s) }.count,
        steps:     Step.count }.tap { |d| after_sync(d) }
      end
    rescue FbResource::FetchError => e
      add_error :web_server, :fetch_error, e.message
    end

    def after_sync(data)
      ["Sync completed at #{Time.now}", data].map { |d| bot.log(d) }
      bot.status_storage.update_attributes(last_sync: Time.now)
      bot.emit_changes
    end
  end
end
