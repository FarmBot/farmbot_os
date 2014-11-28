require 'json'
require './lib/database/dbaccess.rb'
require 'time'
require_relative 'messagehandler_base'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerMeasurement < MessageHandlerBase

  def whitelist
    ["read_measurements","delete_measurements"]
  end

  ## measurements

  # Read measurements from database and send through skynet
  #
  def read_measurements(message)

    @dbaccess.write_to_log(2,'handle read measurements')

    measurements_list = @dbaccess.read_measurement_list()

    return_message =
      {
        :message_type => 'read_measurements_response',
        :time_stamp   => Time.now.to_f.to_s,
        :confirm_id   => message.time_stamp,
        :measurements => measurements_list
      }

    message.handler.send_message(message.sender, return_message)

  end

  # Delete messurements
  #
  def delete_measurements(message)

    @dbaccess.write_to_log(2,'handle read measurements')

    if message.payload.has_key? 'ids'
      message.payload['ids'].each do |id|

        @dbaccess.delete_measurement(id)

      end
    end

    message.handler.send_confirmation(message.sender, message.time_stamp)
  end

end
