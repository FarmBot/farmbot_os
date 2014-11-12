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
    ["single_command","crop_schedule_update","read_parameters","write_parameters","read_logs","read_status","read_measurements","delete_measurements", "emergency_stop","emergency_stop_reset"]
  end

  # Handle the message received from skynet
  #
  def handle_message(message)

    sender     = ""
    time_stamp = nil

    err_msg = ""
    err_trc = ""
    err_snd = false

    # Check if all needed variables are in the message, and send it to the processing function
    begin

      requested_command = ''

      @dbaccess.write_to_log(2,message.to_s)

      sender = (message.has_key? 'fromUuid'  ) ? message['fromUuid']   : ''
      @dbaccess.write_to_log(2,"sender #{sender}")

      if message.has_key? 'payload'
        @message = message['payload']
        if @message.has_key? 'message_type'
          requested_command = message['payload']["message_type"].to_s.downcase
          @dbaccess.write_to_log(2,"message_type = #{requested_command}")
        else
          @dbaccess.write_to_log(2,'message has no message type')

          time_stamp = (message['payload'].has_key? 'time_stamp') ? message['payload']['time_stamp'] : nil
          @dbaccess.write_to_log(2,"time stamp = #{time_stamp}")

          if sender != ''
            send_error(sender, '', 'unknown message type')
          end
        end
      else
        @dbaccess.write_to_log(2,'message has no payload')
        if sender != ''
          send_error(sender, '', 'message has no payload')
        end
      end

      if whitelist.include?(requested_command)
        self.send(requested_command, message)
      else
        @dbaccess.write_to_log(2,'message type not in white list')
        send_error(sender, time_stamp, 'message type not in white list')
      end
    rescue Exception => e
      err_snd = true
      err_msg = e.message
      err_trc = e.backtrace.inspect
    end

    # in case of an error, send error message as a reply
    begin
      if err_snd == true
        if sender != ""
          send_error(sender, time_stamp, " #{err_msg} @ #{err_trc}")
          @dbaccess.write_to_log(2,'Error in message handler.\nError #{err_msg} @ #{err_trc}')
        end
      end
    rescue  Exception => e
      puts 'Error while sending error message: #{e.message}'
    end

  end

  # Handles an error (typically, an unauthorized or unknown message). Returns
  # Hash.
  def error
    return {error: ""}
  end

  ## measurements

  # Read measurements from database and send through skynet
  #
  def read_measurements(message)

    @dbaccess.write_to_log(2,'handle read measurements')

    payload = message['payload']

    time_stamp = (payload.has_key? 'time_stamp') ? payload['time_stamp'] : nil
    sender     = (message.has_key? 'fromUuid'  ) ? message['fromUuid']   : 'UNKNOWN'

    @dbaccess.write_to_log(2,"sender     = #{sender}")
    @dbaccess.write_to_log(2,"time_stamp = #{time_stamp}")

    if time_stamp != @last_time_stamp

      @last_time_stamp = time_stamp

      measurements_list = @dbaccess.read_measurement_list()

      return_message =
        {
          :message_type => 'read_measurements_response',
          :time_stamp   => Time.now.to_f.to_s,
          :confirm_id   => time_stamp,
          :measurements => measurements_list
        }

      $messaging.send_message(sender, return_message)

    end
  end

  def delete_measurements(message)

    @dbaccess.write_to_log(2,'handle read measurements')

    payload = message['payload']

    time_stamp = (payload.has_key? 'time_stamp') ? payload['time_stamp'] : nil
    sender     = (message.has_key? 'fromUuid'  ) ? message['fromUuid']   : 'UNKNOWN'

    @dbaccess.write_to_log(2,"sender     = #{sender}")
    @dbaccess.write_to_log(2,"time_stamp = #{time_stamp}")

    if time_stamp != @last_time_stamp

      @last_time_stamp = time_stamp

      if payload.has_key? 'ids'
        payload['ids'].each do |id|

          @dbaccess.delete_measurement(id)

        end
      end

      command =
        {
          :message_type => 'confirmation',
          :time_stamp   => Time.now.to_f.to_s,
          :confirm_id   => time_stamp
        }

      $messaging.send_message(sender, command)
    end
  end

end
