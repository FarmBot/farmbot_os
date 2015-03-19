require 'json'
require './lib/database/dbaccess.rb'
require 'time'
require_relative 'messagehandler_base'
require_relative 'messagehandler_schedule_cmd_line'
# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerSchedule < MessageHandlerBase

  attr_accessor :message

  WHITELIST = ["single_command","crop_schedule_update"]

  def single_command(message)
    omg = 0
    puts omg += 1
    command = message.payload['command']
    puts omg += 1
    if command
    puts omg += 1
      command = message.payload['command']
    puts omg += 1
      command_obj = MessageHandlerScheduleCmdLine.new
    puts omg += 1
      command_obj.split_command_line( message.payload['command'])
    puts omg += 1
      command_obj.write_to_log()
    puts omg += 1
      save_single_command(command_obj, message.delay)
    puts omg += 1
      Status.current.command_refresh += 1;
    puts omg += 1
      message.handler.send_confirmation(message.sender, message.time_stamp)
    puts omg += 1
    else
    puts omg += 1
       raise 'No command in message'
    end
  end

  def save_single_command(command, delay)
      @dbaccess.create_new_command(Time.now + delay.to_i,'single_command')
      save_command_line(command)
      @dbaccess.save_new_command
      @dbaccess.increment_refresh
  end

  def save_command_line(command)
      @dbaccess.add_command_line(command.action,
                                 command.x.to_i,
                                 command.y.to_i,
                                 command.z.to_i,
                                 command.speed.to_s,
                                 command.amount.to_i,
                                 command.pin_nr.to_i,
                                 command.pin_value1.to_i,
                                 command.pin_value2.to_i,
                                 command.pin_mode.to_i,
                                 command.pin_time.to_i,
                                 command.ext_info)
  end

  def crop_schedule_update(message)
    @dbaccess.write_to_log(2,'handling crop schedule update')

    message_contents = message.payload

    crop_id = message_contents['crop_id']
    @dbaccess.write_to_log(2,"crop_id = #{crop_id}")

    @dbaccess.clear_crop_schedule(crop_id)

    Array(message_contents['commands']).each do |command|
     save_command_with_lines(command)
    end

    message.handler.send_confirmation(message.sender, message.time_stamp)
  end

  def save_command_with_lines(command)

      scheduled_time = Time.parse(command['scheduled_time'])
      crop_id        = command['crop_id']
      @dbaccess.write_to_log(2,"crop command at #{scheduled_time}")
      @dbaccess.create_new_command(scheduled_time, crop_id)

      command['command_lines'].each do |command_line|

        command_obj = MessageHandlerScheduleCmdLine.new
        command_obj.split_command_line( command_line)
        command_obj.write_to_log()
        save_command_line(command_obj)

      end

      @dbaccess.save_new_command
      @dbaccess.increment_refresh
  end

end
