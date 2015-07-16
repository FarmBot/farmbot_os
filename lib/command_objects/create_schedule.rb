# Builds a validated sequence (and collection of steps)
require_relative '../models/schedule'
require_relative '../models/sequence'

module FBPi
  # Was once called ScheduleFactory
  class CreateSchedule < Mutations::Command
    required do
      string :start_time
      string :_id
      string :end_time
      float  :repeat
      string :time_unit, in: Schedule::UNITS_OF_TIME
      string :sequence_id
    end

    optional do
      string :next_time
    end

    def validate
      inputs[:id_on_web_app] = inputs.delete(:_id)
      inputs[:sequence] = Sequence.find_by!(id_on_web_app:
                                            inputs.delete(:sequence_id))
    end

    def execute
      Schedule.create!(inputs)
    end
  end
end
