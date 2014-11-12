require 'json'
require 'time'
require './lib/database/dbaccess.rb'

require_relative 'messagehandler_emergencystop.rb'
require_relative 'messagehandler_logs.rb'
require_relative 'messagehandler_measurements.rb'
require_relative 'messagehandler_message.rb'
require_relative 'messagehandler_parameters.rb'
require_relative 'messagehandler_schedule.rb'
require_relative 'messagehandler_status.rb'


# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandler

  attr_accessor :message

  ## general handling messages

  def initialize
    @dbaccess = DbAccess.new
    @last_time_stamp  = ''

    message_handlers = Array.new
    message_handlers << MessageHandlerEmergencyStop.new
    message_handlers << MessageHandlerLogs.new
    message_handlers << MessageHandlerMeasurements.new
    message_handlers << MessageHandlerParameters.new
    message_handlers << MessageHandlerSchedule.new
    message_handlers << MessageHandlerStatus.new

  end

#  # A list of MessageHandler methods (as strings) that a Skynet User may access.
#  #
#  def whitelist
#    ["single_command","crop_schedule_update","read_parameters","write_parameters","read_logs","read_status","read_measurements","delete_measurements", "emergency_stop","emergency_stop_reset"]
#  end

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

      # retrieve all basic varables from the message and put it into the message object

      sender = (message.has_key? 'fromUuid'  ) ? message['fromUuid']        : ''

      message_obj                 = MessageHandlerMessage.new
      message_obj.sender          = sender
      message_obj.payload         = (message.has_key? 'payload' ) ? message['payload'] : '{}'
      message_obj.message_type    = (message_obj.payload.has_key? 'message_type' ) ? message_obj.payload.['message_type'].to_s.downcase  : ''
      message_obj.time_stamp      = (message_obj.payload.has_key? 'time_stamp'   ) ? message_obj.payload.['time_stamp']                  : nil
      message_obj.message_handler = self

      @dbaccess.write_to_log(2,"sender       = #{message_obj.sender}"       )
      @dbaccess.write_to_log(2,"message_type = #{message_obj.message_type}" )
      @dbaccess.write_to_log(2,"time stamp   = #{message_obj.time_stamp}"   )

      # loop trough all the handlers until one handler does process the message

      message_handlers.each do |handler|
        if message_obj.handled == false
          handler.handle_message( message_obj )
        end
      end
      
      if message_obj.handled == false
        @dbaccess.write_to_log(2,'message could not be handled')
        send_error(sender, '', 'message could not be handled')
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

  # send a reply to the back end system
  #
  def send_confirmation(destination, time_stamp)
    command =
      {
        :message_type => 'confirmation',
        :time_stamp   => Time.now.to_f.to_s,
        :confirm_id   => time_stamp
      }
    $messaging.send_message(destination, command)
  end

  def send_error(destination, time_stamp, error)

    if time_stamp == nil
      time_stamp = Time.now.to_f.to_s
    end

    command =
      {
        :message_type => 'error',
        :time_stamp   => Time.now.to_f.to_s,
        :confirm_id   => time_stamp,
        :error        => error
      }
    $messaging.send_message(destination, command)
  end

end
