module FBPi
  # This Object is responsible for contacting the Farmbot Web App via REST calls
  # in order to fetch the latest command execution schedules. This is a
  # destructive action that will download all Sequences, Schedules and Steps via
  # REST. After fetching the resource, it will destroy all of the local Schedule
  # , Step and Sequence objects and assume that the Web App always has the
  # latests and "most correct" version of Schedule information.
  class SyncBot < Mutations::Command
    required { duck :bot, methods: [:rest_client] }

    def execute
      puts "Attempting to sync now..."
      api = bot.rest_client
      ActiveRecord::Base.transaction do
       [Schedule, Sequence, Step].map(&:destroy_all)
       {sequences: api.sequences.fetch.map { |s| CreateSequence.run!(s) }.count,
        schedules: api.schedules.fetch.map { |s| CreateSchedule.run!(s) }.count,
        plants:    api.plants.fetch.map    { |s| CreatePlant.run!(s) }.count,
        steps:     Step.count }.tap { |d| after_sync(d) }
      end
      puts "Done with sync..."
    rescue FbResource::FetchError => e
      add_error :web_server, :fetch_error, e.message
    end

    def after_sync(data)
      ["Sync completed at #{Time.now}", data].map { |d| bot.log(d) }
      bot.status_storage.update_attributes(:pi, LAST_SYNC: Time.now)
      bot.emit_changes
    end
  end
end
