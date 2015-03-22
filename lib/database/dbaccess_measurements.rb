require 'bson'
require 'sqlite3'
require 'active_record'

require_relative '../../app/models/measurement.rb'

# retrieving and inserting commands into the schedule queue for the farm bot
# using sqlite

# Access class for the database

class DbAccessMeasurements

  attr_writer :dbaccess

  def initialize
  end

  ## measurements

  # write a single measurement
  #
  def write_measurements(value, external_info)
    meas               = Measurement.new
    meas.value         = value
    meas.external_info = external_info
    DbAccess.current.write_sync.synchronize do
      meas.save
    end
  end

  # read measurement list
  #
  def read_measurement_list()
    measurements = Measurement.all
    measurements_list = Array.new

    measurements.each do |meas|
      item =
      {
        'id'         => meas.id,
        'ext_info'   => meas.external_info,
        'timestamp'  => meas.created_at,
        'value'      => meas.value
      }
      measurements_list << item
    end

    measurements_list
  end

  # delete a measurement from the database
  #
  def delete_measurement(id)
    if Measurement.exists?(id)
      meas = Measurement.find(id)
      DbAccess.current.write_sync.synchronize do
        meas.delete
      end
    end
  end

end
