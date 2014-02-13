# Get the JSON command, received through skynet, and send it to the farmbot command queue

require 'json'
require './lib/database/commandqueue.rb'

class MessageHandler

  def initialize
    @command_queue    = CommandQueue.new
    @last_time_stamp  = ''
  end

  def handle_message(skynet, channel, message)

    if message["message_type"].to_s.upcase == "SINGLE_COMMAND"


      # assuming a json message
      #{
      #    "message_type" : "single_command",
      #	   "time_stamp" : 2001-01-01 01:01:01.001
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
  
	puts '[new command]'
	puts "received at #{Time.now}"
	puts "action = #{action}"
	puts "x      = #{x}"
	puts "y      = #{y}"
	puts "z      = #{z}"
	puts "speed  = #{speed}"
	puts "amount = #{amount}"
	puts "delay  = #{delay}"
	  
	@command_queue.create_new_command(Time.now + delay.to_i)
	@command_queue.add_command_line(action, x.to_i, y.to_i, z.to_i, speed.to_s, amount.to_i)
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
end