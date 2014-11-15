require 'json'
require './lib/database/dbaccess.rb'
require 'time'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerSchedule

  attr_accessor :message

  ## general handling messages

  def initialize
    @dbaccess = $bot_dbaccess
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

    if whitelist.include?(message.message_type)
      self.send(message.message_type, message)
      message.handled = true
    end

  end

  def single_command(message)

    @dbaccess.write_to_log(2,'handle single command')

    if message.payload.has_key? 'command' 

      command = message.payload['command']

      # send the command to the queue
	

      delay      = (command.has_key? 'delay' ) ? command['delay'   ] : 0
      action     = (command.has_key? 'action') ? command['action'  ] : 'NOP'
      x          = (command.has_key? 'x'     ) ? command['x'       ] : 0
      y          = (command.has_key? 'y'     ) ? command['y'       ] : 0 
      z          = (command.has_key? 'z'     ) ? command['z'       ] : 0  
      speed      = (command.has_key? 'speed' ) ? command['speed'   ] : 0
      amount     = (command.has_key? 'amount') ? command['amount'  ] : 0
      delay      = (command.has_key? 'delay' ) ? command['delay'   ] : 0

      pin_nr     = (command.has_key? 'pin')    ? command['pin'     ] : 0
      pin_value1 = (command.has_key? 'value1') ? command['value1'  ] : 0
      pin_value2 = (command.has_key? 'value2') ? command['value2'  ] : 0
      pin_mode   = (command.has_key? 'mode'  ) ? command['mode'    ] : 0
      pin_time   = (command.has_key? 'time'  ) ? command['time'    ] : 0
      ext_info   = (command.has_key? 'info'  ) ? command['info'    ] : 0


      @dbaccess.write_to_log(2,"[#{action}] x: #{x}, y: #{y}, z: #{z}, speed: #{speed}, amount: #{amount} delay: #{delay}")
      @dbaccess.write_to_log(2,"[#{action}] pin_nr: #{pin_nr}, value1: #{pin_value1}, value2: #{pin_value2}, mode: #{pin_mode}")
      @dbaccess.write_to_log(2,"[#{action}] ext_info: #{ext_info}")

      @dbaccess.create_new_command(Time.now + delay.to_i,'single_command')
      @dbaccess.add_command_line(action, x.to_i, y.to_i, z.to_i, speed.to_s, amount.to_i, 
        pin_nr.to_i, pin_value1.to_i, pin_value2.to_i, pin_mode.to_i, pin_time.to_i)
      @dbaccess.save_new_command
      $status.command_refresh += 1;

      #@dbaccess.write_to_log(2,'sending comfirmation')

      #$messaging.confirmed = false

      message.handler.send_confirmation(message.sender, message.time_stamp)

    else

      #@dbaccess.write_to_log(2,'no command in message')
      #@dbaccess.write_to_log(2,'sending error')

      #$messaging.confirmed = false
      message.handler.send_error(sender, time_stamp, 'no command in message')

    end

  end

  def crop_schedule_update(message)
    @dbaccess.write_to_log(2,'handling crop schedule update')

    message_contents = message.payload

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

    message.handler.send_confirmation(message.sender, message.time_stamp)

    #$messaging.confirmed = false


  end

end
