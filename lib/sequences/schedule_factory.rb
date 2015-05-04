# Builds a validated sequence (and collection of steps)
require_relative '../models/schedule'

class ScheduleFactory < Mutations::Command
  required do
    string :start_time
    string :_id
    string :end_time
    float  :repeat
    string :time_unit, in: Schedule::UNITS_OF_TIME
    model  :sequence, class: Sequence, builder: SequenceFactory, new_records: true
  end

  optional do
    string :next_time
  end

  def execute
    inputs[:id_on_web_app] = inputs.delete(:_id)
    Schedule.create!(inputs)
  end
end
