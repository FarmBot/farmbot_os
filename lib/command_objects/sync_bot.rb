module FBPi
  # Was once called ScheduleFactory
  class SyncBot < Mutations::Command
    required do
      duck :bot, methods: [:rest_client]
    end

    def execute
      api = bot.rest_client
      ActiveRecord::Base.transaction do
        JoinSequenceSchedules
          .run!(schedules: api.schedules.fetch,
                sequences: api.sequences.fetch)
          .tap { Schedule.destroy_all }
          .map { |s| CreateSchedule.run!(s) }
      end
      bot.log(name: "Sync Confirmation",
              schedules: Schedule.count,
              sequences: Sequence.count,
              steps:     Step.count)
      Schedule.all
    end
  end
end
