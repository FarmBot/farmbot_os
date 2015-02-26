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
require_relative 'messagehandler_message'

class NullDatabase
  def method_missing(*)
    self
  end
end

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandler

  attr_accessor :message
  attr_accessor :use_test_handler

  ## general handling messages

  def initialize
    #@dbaccess = DbAccess.new
    @dbaccess = $dbaccess || NullDatabase.new
    @last_time_stamp  = ''

    @message_handlers = Array.new
    @message_handlers << MessageHandlerEmergencyStop.new
    @message_handlers << MessageHandlerLog.new
    @message_handlers << MessageHandlerMeasurement.new
    @message_handlers << MessageHandlerParameter.new
    @message_handlers << MessageHandlerSchedule.new
    @message_handlers << MessageHandlerStatus.new
    @message_handlers << MessageHandlerMessage.new

  end

  # Handle the message received from skynet
  #
  def handle_message(message)
    puts "WebSocket Message"
    sender     = ""
    time_stamp = nil

    puts "received at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}: #{message}" if $mesh_msg_print == 1

    err_msg = ""
    err_trc = ""
    err_snd = false

    # Check if all needed variables are in the message, and send it to the processing function
    begin

      #requested_command = ''

      @dbaccess.write_to_log(3,message.to_s)
      sender = (message.has_key? 'fromUuid'  ) ? message['fromUuid']        : ''
      message_obj = MessageHandlerMessage.new

      split_message(message, message_obj)
      log_message_obj_info(message_obj)
      send_message_obj_to_individual_handlers(message_obj)
      check_if_message_handled(message_obj)

    rescue Exception => e
      puts e.message, e.backtrace.first
      err_snd = true
      err_msg = e.message
      err_trc = e.backtrace.inspect
    end

    # in case of an error, send error message as a reply
    begin
      handle_message_error(err_snd, sender, time_stamp, err_msg, err_trc)
    rescue  Exception => e
      puts e.message, e.backtrace.first
      puts "Error while sending error message: #{e.message}"
    end
  end

  # Handles an error (typically, an unauthorized or unknown message). Returns
  # Hash.
  def error
    return {error: ""}
  end

  def handle_message_error(err_snd, sender, time_stamp, err_msg, err_trc)
    if err_snd == true
      if sender != ""
        send_error(sender, time_stamp, " #{err_msg} @ #{err_trc}")
        @dbaccess.write_to_log(2,"Error in message handler.\nError #{err_msg} @ #{err_trc}")
      end
    end
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
    send_message(destination, command)
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

    send_message(destination, command)
  end

  def send_message(destination, command)
    @dbaccess.write_to_log(3,"to #{destination} : #{command.to_s}")
    $messaging.send_message(destination, command)
  end

  def split_message(message, message_obj)
    message_obj.sender          = (message.has_key? 'fromUuid'  ) ? message['fromUuid']  : ''
    message_obj.payload         = (message.has_key? 'payload'   ) ? message['payload']   : '{}'
    message_obj.message_type    = (message_obj.payload.has_key? 'message_type' ) ? message_obj.payload['message_type'].to_s.downcase  : ''
    message_obj.time_stamp      = (message_obj.payload.has_key? 'time_stamp'   ) ? message_obj.payload['time_stamp']                  : nil
    message_obj.handler         = self
    message_obj.handled         = false
  end

  def log_message_obj_info(message_obj)
    @dbaccess.write_to_log(2,"sender       = #{message_obj.sender}"       )
    @dbaccess.write_to_log(2,"message_type = #{message_obj.message_type}" )
    @dbaccess.write_to_log(2,"time stamp   = #{message_obj.time_stamp}"   )
  end

  def send_message_obj_to_individual_handlers(message_obj)
    # loop trough all the handlers until one handler does process the message
    @message_handlers.each do |handler|
      if message_obj.handled == false
        handler.handle_message( message_obj )
      end
    end
  end

  def check_if_message_handled(message_obj)
    if message_obj.handled == false
      @dbaccess.write_to_log(2,'message could not be handled')
      send_error(message_obj.sender, '', 'message could not be handled')
    end
  end

end

