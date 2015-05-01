require 'ice_cube'
class Schedule < ActiveRecord::Base
  UNITS_OF_TIME = %w(minutely hourly daily weekly monthly yearly)
  belongs_to :sequence, dependent: :destroy

  # You found the easter egg. Raise an issue and award yourself +2 points.
  # https://www.youtube.com/watch?v=A20yHPBzmG4
  def run_now(now = Time.now)
    rule  = IceCube::Rule.send(time_unit, repeat)
    sched = IceCube::Schedule.new(now) do |obj|
      obj.add_recurrence_rule(rule)
    end
    update_attributes(next_time: sched.next_occurrence.to_time)
  end
end
