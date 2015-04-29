# Builds a validated sequence (and collection of steps)
require_relative "schedule"
# SCHEMA NEEDED FOR PERSISTENCE:
# SEQUENCE: [:name]
# SCHEDULE: [:start_time, :end_time, :repeat, :time_unit, :sequence, :sequence_id]
# STEP:     [:message_type, :x, :y, :z, :speed, :pin, :value, :mode, :sequence_id]
class ScheduleFactory < Mutations::Command
  required do
    string :start_time
    string :end_time
    float  :repeat
    string :time_unit, in: Schedule::UNITS_OF_TIME
    model  :sequence, class: Sequence, builder: SequenceFactory
  end

  def validate
    parse_dates
  end

  def execute
    Schedule.new(inputs)
  end

  private

  def parse_dates
    [:start_time, :end_time].each do |time|
      @last = time
      new_time = Time.parse(self.send(time))
      self.send("#{time}=", new_time) # So Meta!
     end
  rescue ArgumentError => error
    field = @last || :time
    add_error field, :cant_parse, "Error parsing #{field} on Schedule object."\
                                  " #{error.message}"
  end

end
