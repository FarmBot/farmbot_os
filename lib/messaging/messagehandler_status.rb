require 'json'
require './lib/database/dbaccess.rb'
require 'time'
require_relative 'messagehandler_base'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerStatus < MessageHandlerBase

  def whitelist
    ["read_status"]
  end

  # Send the current status to the requester
  #
  def read_status(message)
puts "status"
puts message
    @dbaccess.write_to_log(2,'handle read status')

    $bot_control.read_hw_status()

    return_message =
      {
        :message_type                   => 'read_status_response',
        :time_stamp                     => Time.now.to_f.to_s,
        :confirm_id                     => message.time_stamp,

        :status                         => $status.info_status,
        :status_time_local              => Time.now,
        :status_nr_msg_received         => $info_nr_msg_received,
        :status_movement                => $status.info_movement,
        :status_last_command_executed   => $status.info_command_last,
        :status_next_command_scheduled  => $status.info_command_next,
        :status_nr_of_commands_executed => $status.info_nr_of_commands,
        :status_current_x               => $status.info_current_x,
        :status_current_y               => $status.info_current_y,
        :status_current_z               => $status.info_current_z,
        :status_target_x                => $status.info_target_x,
        :status_target_y                => $status.info_target_y,
        :status_target_z                => $status.info_target_z,
        :status_end_stop_x_a            => $status.info_end_stop_x_a,
        :status_end_stop_x_b            => $status.info_end_stop_x_b,
        :status_end_stop_y_a            => $status.info_end_stop_y_a,
        :status_end_stop_y_b            => $status.info_end_stop_y_b,
        :status_end_stop_z_a            => $status.info_end_stop_z_a,
        :status_end_stop_z_b            => $status.info_end_stop_z_b
      }

     @dbaccess.write_to_log(2,"return_message = #{return_message}")

     message.handler.send_message(message.sender, return_message)

  end
end
