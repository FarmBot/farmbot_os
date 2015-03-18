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

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandler

  attr_accessor :message
  attr_accessor :messaging
  attr_accessor :use_test_handler

  ## general handling messages

  def initialize(messaging)

    @messaging = messaging
    @dbaccess = DbAccess.current
    @last_time_stamp  = ''
    @message_handlers = [MessageHandlerEmergencyStop.new(messaging),
                         MessageHandlerLog.new(messaging),
                         MessageHandlerMeasurement.new(messaging),
                         MessageHandlerParameter.new(messaging),
                         MessageHandlerSchedule.new(messaging),
                         MessageHandlerStatus.new(messaging)]
  end

  # Handle the message received from skynet
  #
  def handle_message(message)
    maybe_print(message)
    msg = MessageHandlerMessage.new(message, self)
    send_message_obj_to_individual_handlers(msg)
    check_if_message_handled(msg)
  rescue => e
    sender = msg.try(:sender) || "UNKNOWN-SENDER"
    # require 'pry'
    # binding.pry
    send_error(sender, e)
  end

  # Handles an error (typically, an unauthorized or unknown message). Returns
  # Hash.
  def error
    {error: ""}
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

  def send_error(destination, error, time_stamp = Time.now.to_f.to_s)
    err_msg = "#{error.message} @ #{error.backtrace.first}"
    puts err_msg
    command = { :message_type => 'error',
                :time_stamp   => Time.now.to_f.to_s,
                :confirm_id   => time_stamp,
                :error        => err_msg }

    send_message(destination, command)
  rescue => e
    puts "Error while sending error message:", e.message, e.backtrace.first
  end

  def send_message(destination, command)
    @messaging.send_message(destination, command)
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
    raise 'message could not be handled' if message_obj.handled == false
  rescue => e
    send_error(message_obj.sender, e)
  end

  # Print incoming JSON as YAML, but only if it's not a read_status message.
  def maybe_print(message)
    is_status = message["payload"].try(:[], "message_type") == "read_status"
    STDOUT.puts "\n#{message.to_yaml}\n" unless is_status
  end

end

