require 'json'
require './lib/database/dbaccess.rb'
require 'time'
require_relative 'messagehandler_base'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerLog < MessageHandlerBase

  def whitelist
    ["read_logs"]
  end

  # Read logs from database and send through skynet
  #
  def read_logs(message)

    @dbaccess.write_to_log(2,'handle read logs')

    logs = @dbaccess.read_logs_all()

    log_list = Array.new
    logs.each do |log|
      item =
      {
        'text'   => log.text,
        'module' => log.module_id,
        'time'   => log.created_at
      }
      log_list << item
    end

    return_message =
      {
        :message_type => 'read_logs_response',
        :time_stamp   => Time.now.to_f.to_s,
        :confirm_id   => message.time_stamp,
        :logs         => log_list
      }

    message.handler.send_message(message.sender, return_message)

  end

end
