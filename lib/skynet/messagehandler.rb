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

  # Main entry point for (Hash) commands coming in over SkyNet.
  # {
  #    "message_type" : "single_command",
  #    "time_stamp" : 2001-01-01 01:01:01.001
  #    "command" : {
  #      "action" : "HOME X",
  #      "x" : 1,
  #      "y" : 2,
  #      "z" : 3,
  #      "speed" : "FAST",
  #      "amount" : 5,
  #      "delay" : 6
  #   }
  # }

  def handle_message(message)

    puts 'handle_message'
    #puts message
    #puts message['message']

    @message = message['message']
    #fromUuid = message['fromUuid']
    #puts fromUuid 

    requested_command = message['message']["message_type"].to_s.downcase
    #puts requested_command

    if whitelist.include?(requested_command)
      #puts 'sending'
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

    puts 'single_command'
    #puts message

    time_stamp = message['message']['time_stamp']
    sender = message['fromUuid']

    if time_stamp != @last_time_stamp
      @last_time_stamp = time_stamp


      # send the command to the queue
      delay  = message['message']['command']['delay']
      action = message['message']['command']['action']
      x      = message['message']['command']['x']
      y      = message['message']['command']['y']
      z      = message['message']['command']['z']
      speed  = message['message']['command']['speed']
      amount = message['message']['command']['amount']
      delay  = message['message']['command']['delay']

      puts "[new command] received at #{Time.now} from #{sender}"
      puts "[#{action}] x: #{x}, y: #{y}, z: #{z}, speed: #{speed}, amount: #{amount} delay: #{delay}"

      @dbaccess.create_new_command(Time.now + delay.to_i,'single_command')
      @dbaccess.add_command_line(action, x.to_i, y.to_i, z.to_i, speed.to_s, amount.to_i)
      @dbaccess.save_new_command

      $skynet.confirmed = false

      command =
        {
          :message_type => 'confirmation',
          :time_stamp   => Time.now.to_f.to_s,
          :confirm_id   => time_stamp
        }

       $skynet.send_message(sender, command)

    end
  end

  def crop_schedule_update(message)

    puts 'crop_schedule_update'
    #puts message

    time_stamp = message['message']['time_stamp']
    sender = message['fromUuid']

    puts "time_stamp #{time_stamp}"
    puts "sender #{sender}"

    if time_stamp != @last_time_stamp
      @last_time_stamp = time_stamp


      message_contents = message['message']
      #puts message_contents

      crop_id = message_contents['crop_id']
      puts crop_id

      puts 'removing old crop schedule'
      @dbaccess.clear_crop_schedule(crop_id)

      message_contents['commands'].each do |command|

        #puts command
        #puts command.class
        #puts command[0]
        #puts command[0].class
        #puts command[1]
        #puts command[1].class

        scheduled_time = Time.parse(command[1]['scheduled_time'])
        
        @dbaccess.create_new_command(scheduled_time, crop_id)
        #@dbaccess.create_new_command(Time.now, 'debug')
        puts scheduled_time
        puts Time.now

        command[1]['command_lines'].each do |command_line|

          action = command_line[1]['action']
          x      = command_line[1]['x']
          y      = command_line[1]['y']
          z      = command_line[1]['z']
          speed  = command_line[1]['speed']
          amount = command_line[1]['amount']


          puts "[#{action}] x: #{x}, y: #{y}, z: #{z}, speed: #{speed}, amount: #{amount}"
          @dbaccess.add_command_line(action, x.to_i, y.to_i, z.to_i, speed.to_s, amount.to_i)

        end

        @dbaccess.save_new_command

      end

      # send the command to the queue
      #delay  = message['message']['command']['delay']
      #action = message['message']['command']['action']
      #x      = message['message']['command']['x']
      #y      = message['message']['command']['y']
      #z      = message['message']['command']['z']
      #speed  = message['message']['command']['speed']
      #amount = message['message']['command']['amount']
      #delay  = message['message']['command']['delay']

      #puts "[new command] received at #{Time.now} from #{sender}"
      #puts "[#{action}] x: #{x}, y: #{y}, z: #{z}, speed: #{speed}, amount: #{amount} delay: #{delay}"

      #@dbaccess.create_new_command(Time.now + delay.to_i)
      #@dbaccess.add_command_line(action, x.to_i, y.to_i, z.to_i, speed.to_s, amount.to_i)
      #@dbaccess.save_new_command

      puts 'sending comfirmation'

      $skynet.confirmed = false

      command =
        {
          :message_type => 'confirmation',
          :time_stamp   => Time.now.to_f.to_s,
          :confirm_id   => time_stamp
        }

       $skynet.send_message(sender, command)

    end
  end


end
