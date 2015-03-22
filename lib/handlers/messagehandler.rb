require 'json'
require 'time'
require './lib/database/dbaccess.rb'

require_relative 'messagehandler_emergencystop'
require_relative 'messagehandler_logs'
require_relative 'messagehandler_measurements'
require_relative 'messagehandler_message'
require_relative 'messagehandler_parameters'
require_relative 'messagehandler_schedule'
require_relative 'messagehandler_status'
require_relative 'messagehandler_message'
require_relative 'messagehandler_null'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandler

  attr_accessor :message, :messaging, :use_test_handler

  ## general handling messages
    ROUTES =
    { "read_logs"            => MessageHandlerLog,
      "emergency_stop"       => MessageHandlerEmergencyStop,
      "emergency_stop_reset" => MessageHandlerEmergencyStop,
      "read_measurements"    => MessageHandlerMeasurement,
      "delete_measurements"  => MessageHandlerMeasurement,
      "read_parameters"      => MessageHandlerParameter,
      "write_parameters"     => MessageHandlerParameter,
      "single_command"       => MessageHandlerSchedule,
      "crop_schedule_update" => MessageHandlerSchedule,
      "read_status"          => MessageHandlerStatus,
      "everything else"      => MessageHandlerNull, }


  def initialize(messaging)
    @messaging = messaging
    @dbaccess = DbAccess.current
    @last_time_stamp  = ''
  end

  # Handle the message received from skynet
  #
  def handle_message(message)
    maybe_print(message)
    msg = MessageHandlerMessage.new(message, self)
    route_message(msg)
  rescue => e
    sender = msg.try(:sender) || "UNKNOWN-SENDER"
    send_error(sender, e)
  end

  # send a reply to the back end system
  #
  def send_confirmation(destination, time_stamp)
    command = { :message_type => 'confirmation',
                :time_stamp   => Time.now.to_f.to_s,
                :confirm_id   => time_stamp }
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

  def route_message(message_obj)
    handler_class = ROUTES[message_obj.message_type] || MessageHandlerNull
    handler_class
      .new(messaging)
      .handle_message(message_obj)
  end

  # Print incoming JSON as YAML, but only if it's not a read_status message.
  def maybe_print(message)
    is_status = message["payload"].try(:[], "message_type") == "read_status"
    STDOUT.puts "\n#{message.to_yaml}\n" unless is_status
  end
end

