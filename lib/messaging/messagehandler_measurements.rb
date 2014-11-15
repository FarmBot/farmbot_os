require 'json'
require './lib/database/dbaccess.rb'
require 'time'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandler

  attr_accessor :message

  ## general handling messages

  def initialize
    @dbaccess = DbAccess.new
    @last_time_stamp  = ''
  end

  # A list of MessageHandler methods (as strings) that a Skynet User may access.
  #
  def whitelist
    ["read_measurements","delete_measurements"]
  end

  # Handle the message received from skynet
  #
  def handle_message(message)

    handled = false

    if whitelist.include?(message.message_type)
      self.send(message)
      handled = true
    end

    handled
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
        :confirm_id   => time_stamp,
        :measurements => measurements_list
      }

    message.hander.send_message(sender, return_message)

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

    command =
      {
        :message_type => 'confirmation',
        :time_stamp   => Time.now.to_f.to_s,
        :confirm_id   => time_stamp
      }

    message.handler.send_message(sender, command)
  end

end
