require 'spec_helper'
require './lib/status.rb'
require './lib/messaging/messagehandler.rb'
require './lib/messaging/messaging_test.rb'
require './lib/messaging/messagehandler_parameters.rb'

describe MessageHandlerParameter do

  before do
    $db_write_sync = Mutex.new
    DbAccess.current = DbAccess.new('development')
    DbAccess.current = DbAccess.current
    DbAccess.current.disable_log_to_screen()

    $status = Status.new

    @messaging = MessagingTest.new
    @messaging.reset

    @handler = MessageHandlerParameter.new
    @main_handler = MessageHandler.new
  end

  ## measurements

  it "white list" do
    list = @handler.whitelist
    expect(list.count).to eq(2)
  end

  it "read parameters" do

    # write a few parameters
    parameter_value_1 = rand(9999999).to_i
    parameter_name_1  = rand(9999999).to_s
    DbAccess.current.write_parameter(parameter_name_1, parameter_value_1)

    parameter_value_2 = rand(9999999).to_i
    parameter_name_2  = rand(9999999).to_s
    DbAccess.current.write_parameter(parameter_name_2, parameter_value_2)

    # get the list of parameters that the system will send

    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler

    @handler.read_parameters(message)

    return_list = @messaging.message

    # check if the parameters are present in the message

    found_in_list_1       = false
    found_in_list_2       = false

    return_list[:parameters].each do |item|
      if item['value'] == parameter_value_1 and item['name'] == parameter_name_1
        found_in_list_1 = true
      end
      if item['value'] == parameter_value_2 and item['name'] == parameter_name_2
        found_in_list_2 = true
      end
    end

    # check expectations

    expect(found_in_list_1).to eq(true)
    expect(found_in_list_2).to eq(true)
    expect(@messaging.message[:message_type]).to eq('read_parameters_response')
  end

  it "write parameters" do

    # write a few parameters

    parameter_name_1   = rand(9999999).to_s
    parameter_name_2   = rand(9999999).to_s
    parameter_value_1  = rand(9999999).to_i
    parameter_value_2  = rand(9999999).to_i

    # write a value using a message

    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler
    #message.payload = {'ids' => [id_1,id_2]}
    message.payload =
      {
        'parameters' =>
          [
            {'name' => parameter_name_1, 'type' => 1, 'value' => parameter_value_1},
            {'name' => parameter_name_2, 'type' => 1, 'value' => parameter_value_2}
          ]
      }

    @handler.write_parameters(message)

    # check if the parameters in the database have the right values

    value_read_1          = DbAccess.current.read_parameter(parameter_name_1)
    value_read_2          = DbAccess.current.read_parameter(parameter_name_2)

    # check expectations

    expect(value_read_1).to eq(parameter_value_1)
    expect(value_read_2).to eq(parameter_value_2)
    expect(@messaging.message[:message_type]).to eq('confirmation')

  end

  it "write parameters empty command" do


    message = MessageHandlerMessage.new
    message.handled = false
    message.handler = @main_handler
    message.payload = {}

    @handler.write_parameters(message)

    expect(@messaging.message[:message_type]).to eq('error')

  end

end
