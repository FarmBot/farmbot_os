require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

  ## measurements

  it "write measurement" do
    
    measurement_value = rand(9999999).to_i
    measurement_text  = rand(9999999).to_s
    @db.write_measurements(measurement_value, measurement_text)

    measurements = Measurement.where("value = ? and external_info = ?",measurement_value, measurement_text)

    expect(measurements.count).to eq(1)
  end

  it "read measurent list" do
    found_in_list = false

    measurement_value = rand(9999999).to_i
    measurement_text  = rand(9999999).to_s
    @db.write_measurements(measurement_value, measurement_text)

    return_list = @db.read_measurement_list()

    return_list.each do |item|
      if item['value'] == measurement_value and item['ext_info'] == measurement_text
        found_in_list = true
      end
    end

    expect(found_in_list).to eq(true)
  end

  it "delete measurement" do

    measurement_value = rand(9999999).to_i
    measurement_text  = rand(9999999).to_s
    @db.write_measurements(measurement_value, measurement_text)

    id = Measurement.where("value = ? and external_info = ?",measurement_value, measurement_text).last.id
        
    @db.delete_measurement(id)

    measurements = Measurement.where("value = ? and external_info = ?",measurement_value, measurement_text)
    expect(measurements.count).to eq(0)
  end

end
