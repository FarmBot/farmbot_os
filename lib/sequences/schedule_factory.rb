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

  def validate
    parse_dates
  end

  def execute
    inputs[:id_on_web_app] = inputs.delete(:_id)
    Schedule.create!(inputs)
  end

  private

  def parse_dates
    [:start_time, :end_time].each do |time|
      @last = time
      binding.pry
      new_time = Time.parse(self.send(time))
      self.send("#{time}=", new_time) # So Meta!
     end
  rescue ArgumentError => error
    field = @last || :time
    add_error field, :cant_parse, "Error parsing #{field} on Schedule object."\
                                  " #{error.message}"
  end

end
