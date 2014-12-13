require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

  ## measurements

#  def write_measurements(value, external_info)
#    @measurements.write_measurements(value, external_info)
#  end

#  def read_measurement_list()
#    @measurements.read_measurement_list()
#  end

#  def delete_measurement(id)
#    @measurements.delete_measurement(id)
#  end

end
