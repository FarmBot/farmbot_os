require 'json'
require './lib/database/commandqueue.rb'

# Get the JSON command, received through skynet, and send it to the farmbot command queue
# Parses JSON messages received through SkyNet. 
class MessageHandler

  attr_accessor :message

  def initialize
    @command_queue    = CommandQueue.new
    @last_time_stamp  = ''
  end

  # A list of MessageHandler methods (as strings) that a Skynet User may access.
  #
  def whitelist
    ["single_command"]
  end

  # Main entry point for (Hash) commands coming in over SkyNet.
  #{
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
  #}
  def handle_message(skynet, channel, message)
    @message = message
    requested_command = message["message_type"].to_s.downcase
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
    time_stamp = message['time_stamp']
    
    if time_stamp != @last_time_stamp
      @last_time_stamp = time_stamp

      # send the command to the queue
      delay  = message['command']['delay']
      action = message['command']['action']
      x      = message['command']['x']
      y      = message['command']['y']
      z      = message['command']['z']
      speed  = message['command']['speed']
      amount = message['command']['amount']
      delay  = message['command']['delay']

      puts "[new command] received at #{Time.now}"
      puts "[#{action}] x: #{x}, y: #{y}, z: #{z}, speed: #{speed}, amount: "\
           "#{amount} delay: #{delay}"
        
      @command_queue.create_new_command(Time.now + delay.to_i)
      @command_queue.add_command_line(action, x.to_i, y.to_i, z.to_i, 
        speed.to_s, amount.to_i)
      @command_queue.save_new_command

      skynet.confirmed = false
      command =
        {
          :message_type => 'confirmation',
          :time_stamp   => Time.now.to_f.to_s,
          :confirm_id   => time_stamp
          }

       skynet.send_message("44128811-8c59-11e3-b99a-11476114e05f", command)

    end
  end
end