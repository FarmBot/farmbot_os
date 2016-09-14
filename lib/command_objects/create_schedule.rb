require_relative '../models/schedule'
require_relative '../models/sequence'

module FBPi
  # Acts as a factory for schedule objects. Used mostly when the RPi is fetching
  # JSON schedule objects off of the web app's API (format 1) and needs to
  # transform the schedules into a format that is usable by the RPi and storable
  # in SQLite (via ActiveRecord)
  class CreateSchedule < Mutations::Command
    required do
      string :start_time
      string :id
      string :end_time
      float  :repeat
      string :time_unit, in: Schedule::UNITS_OF_TIME
      string :sequence_id
    end

    optional do
      string :next_time
    end

    def validate
      inputs[:id_on_web_app] = inputs.delete(:id)
      inputs[:sequence] = Sequence.find_by!(id_on_web_app:
                                            inputs.delete(:sequence_id))
    end

    def execute
      Schedule.create!(inputs)
    end
  end
end
