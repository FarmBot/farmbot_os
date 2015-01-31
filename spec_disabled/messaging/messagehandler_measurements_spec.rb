require 'spec_helper'
require './lib/status.rb'
require './lib/messaging/messaging.rb'
require './lib/messaging/messaging_test.rb'
require './lib/messaging/messagehandler_measurements.rb'

describe MessageHandlerMeasurement do

  before do
    $db_write_sync = Mutex.new
    $bot_dbaccess = DbAccess.new('development')
    $dbaccess = $bot_dbaccess
    $dbaccess.disable_log_to_screen()

    $status = Status.new

    $messaging = MessagingTest.new
    $messaging.reset

    @handler = MessageHandlerMeasurement.new
    @main_handler = MessageHandler.new
  end

  ## measurements

  
  it "read measurements" do

    # write a measurement
    measurement_value = rand(9999999).to_i
    measurement_text  = rand(9999999).to_s
    $dbaccess.write_measurements(measurement_value, measurement_text)

    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler

    # read the list of measurements
    @handler.read_measurements(message)

    # check if the created item is into the list to send
    found_in_list = false
    $messaging.message[:measurements].each do |item|
      if item['value'] == measurement_value and item['ext_info'] == measurement_text
        found_in_list = true
      end
    end

    expect(found_in_list).to eq(true)
    expect($messaging.message[:message_type]).to eq('read_measurements_response')
  end

  it "delete measurement" do

    # write two measurements
    measurement_value_1 = rand(9999999).to_i
    measurement_text_1  = rand(9999999).to_s
    $dbaccess.write_measurements(measurement_value_1, measurement_text_1)

    measurement_value_2 = rand(9999999).to_i
    measurement_text_2  = rand(9999999).to_s
    $dbaccess.write_measurements(measurement_value_2, measurement_text_2)

    # check if the measurements are in the database and get the id
    found_in_list_1       = false
    found_in_list_2       = false
    found_in_list_1_after = false
    found_in_list_2_after = false
    id_1                  = 0
    id_2                  = 0
    return_list = $dbaccess.read_measurement_list()

    return_list.each do |item|
      if item['value'] == measurement_value_1 and item['ext_info'] == measurement_text_1
        found_in_list_1 = true
        id_1 = item['id']
      end
      if item['value'] == measurement_value_2 and item['ext_info'] == measurement_text_2
        found_in_list_2 = true
        id_2 = item['id']
      end
    end

    # try to delete the measurements
    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler
    message.payload = {'ids' => [id_1,id_2]}

    @handler.delete_measurements(message)


    # check if the measurements are still in the database and get the id
    found_in_list_1_after = false
    found_in_list_2_after = false
    return_list = $dbaccess.read_measurement_list()

    return_list.each do |item|
      if item['value'] == measurement_value_1 and item['ext_info'] == measurement_text_1
        found_in_list_1_after = true
      end
      if item['value'] == measurement_value_2 and item['ext_info'] == measurement_text_2
        found_in_list_2_after = true
      end
    end


    expect(found_in_list_1).to eq(true)
    expect(found_in_list_2).to eq(true)
    expect(found_in_list_1_after).to eq(false)
    expect(found_in_list_2_after).to eq(false)
    expect($messaging.message[:message_type]).to eq('confirmation')

  end

end
