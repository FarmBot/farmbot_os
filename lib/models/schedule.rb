class Schedule < ActiveRecord::Base
  UNITS_OF_TIME = %w(minutely hourly daily weekly monthly yearly)
  belongs_to :sequence, dependent: :destroy
end
