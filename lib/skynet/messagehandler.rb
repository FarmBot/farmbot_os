require 'json'
#require './lib/database/commandqueue.rb'
require './lib/database/dbaccess.rb'
require 'time'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandler

  attr_accessor :message

  def initialize
    @dbaccess = DbAccess.new
    @last_time_stamp  = ''
  end

  # A list of MessageHandler methods (as strings) that a Skynet User may access.
  #
  def whitelist
    ["single_command","crop_schedule_update"]
  end

  # Handle the message received from skynet
  #
  def handle_message(message)

    @dbaccess.write_to_log(2,message.to_s)
    @message = message['payload']

    requested_command = message['payload']["message_type"].to_s.downcase
    @dbaccess.write_to_log(2,'command = #{requested_command}')

    if whitelist.include?(requested_command)
      self.send(requested_command, message)
    else
      self.error(message)
    end
  end

  # Handles an erorr (typically, an unauthorized or unknown message). Returns
  # Hash.
  def error
    return {error: ""}
  end

  def single_command(message)

    @dbaccess.write_to_log(2,'handle single command')

    time_stamp = message['payload']['time_stamp']
    sender = message['fromUuid']
    @dbaccess.write_to_log(2,"sender = #{sender}")

    if time_stamp != @last_time_stamp
      @last_time_stamp = time_stamp


      # send the command to the queue
      delay  = message['payload']['command']['delay']
      action = message['payload']['command']['action']
      x      = message['payload']['command']['x']
      y      = message['payload']['command']['y']
      z      = message['payload']['command']['z']
      speed  = message['payload']['command']['speed']
      amount = message['payload']['command']['amount']
      delay  = message['payload']['command']['delay']

      @dbaccess.write_to_log(2,"[#{action}] x: #{x}, y: #{y}, z: #{z}, speed: #{speed}, amount: #{amount} delay: #{delay}")

      @dbaccess.create_new_command(Time.now + delay.to_i,'single_command')
      @dbaccess.add_command_line(action, x.to_i, y.to_i, z.to_i, speed.to_s, amount.to_i)
      @dbaccess.save_new_command

      @dbaccess.write_to_log(2,'sending comfirmation')

      $skynet.confirmed = false

      command =
        {
          :message_type => 'confirmation',
          :time_stamp   => Time.now.to_f.to_s,
          :confirm_id   => time_stamp
        }

       $skynet.send_message(sender, command)

      @dbaccess.write_to_log(2,'done')

    end
  end

  def crop_schedule_update(message)

    @dbaccess.write_to_log(2,'handling crop schedule update')

    time_stamp = message['payload']['time_stamp']
    sender = message['fromUuid']
    @dbaccess.write_to_log(2,"sender = #{sender}")

    if time_stamp != @last_time_stamp
      @last_time_stamp = time_stamp


      message_contents = message['payload']

      crop_id = message_contents['crop_id']
      @dbaccess.write_to_log(2,"crop_id = #{crop_id}")

      @dbaccess.clear_crop_schedule(crop_id)

      message_contents['commands'].each do |command|

        scheduled_time = Time.parse(command['scheduled_time'])
        @dbaccess.write_to_log(2,"crop command at #{scheduled_time}")
        @dbaccess.create_new_command(scheduled_time, crop_id)

        command['command_lines'].each do |command_line|

          action = command_line['action']
          x      = command_line['x']
          y      = command_line['y']
          z      = command_line['z']
          speed  = command_line['speed']
          amount = command_line['amount']


          @dbaccess.write_to_log(2,"[#{action}] x: #{x}, y: #{y}, z: #{z}, speed: #{speed}, amount: #{amount}")
          @dbaccess.add_command_line(action, x.to_i, y.to_i, z.to_i, speed.to_s, amount.to_i)

        end

        @dbaccess.save_new_command

      end

      @dbaccess.write_to_log(2,'sending comfirmation')

      $skynet.confirmed = false

      command =
        {
          :message_type => 'confirmation',
          :time_stamp   => Time.now.to_f.to_s,
          :confirm_id   => time_stamp
        }

       $skynet.send_message(sender, command)

      @dbaccess.write_to_log(2,'done')


    end
  end


end
