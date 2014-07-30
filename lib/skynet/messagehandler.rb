require 'json'
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
    ["single_command","crop_schedule_update","read_parameters","write_parameters","read_logs","read_status"]
  end

  # Handle the message received from skynet
  #
  def handle_message(message)

    sender     = ""
    time_stamp = nil

    err_msg = ""
    err_trc = ""
    err_snd = false

    # Check if all needed variables are in the message, and send it to the processing function
    begin

      requested_command = ''

      @dbaccess.write_to_log(2,message.to_s)

      sender = (message.has_key? 'fromUuid'  ) ? message['fromUuid']   : ''
      @dbaccess.write_to_log(2,"sender #{sender}")

      if message.has_key? 'payload'
        @message = message['payload']
        if @message.has_key? 'message_type'
          requested_command = message['payload']["message_type"].to_s.downcase
          @dbaccess.write_to_log(2,"message_type = #{requested_command}")
        else
          @dbaccess.write_to_log(2,'message has no message type')

          time_stamp = (message['payload'].has_key? 'time_stamp') ? message['payload']['time_stamp'] : nil
          @dbaccess.write_to_log(2,"time stamp = #{time_stamp}")

          if sender != ''
            send_error(sender, '', 'unknown message type')
          end
        end
      else
        @dbaccess.write_to_log(2,'message has no payload')
        if sender != ''
          send_error(sender, '', 'message has no payload')
        end
      end

      if whitelist.include?(requested_command)
        self.send(requested_command, message)
      else
        @dbaccess.write_to_log(2,'message type not in white list')
        self.error(message)
      end
    rescue Exception => e
      err_snd = true
      err_msg = e.message
      err_trc = e.backtrace.inspect
    end

    # in case of an error, send error message as a reply
    begin
      if err_snd == true
        if sender != ""
          send_error(sender, time_stamp, " #{err_msg} @ #{err_trc}")
          @dbaccess.write_to_log(2,'Error in message handler.\nError #{err_msg} @ #{err_trc}')
        end
      end
    rescue  Exception => e
      puts 'Error while sending error message: #{e.message}'
    end

  end

  # Handles an error (typically, an unauthorized or unknown message). Returns
  # Hash.
  def error
    return {error: ""}
  end

  # Send the current status to the requester
  #
  def read_status(message)

    @dbaccess.write_to_log(2,'handle read status')

    payload = message['payload']

    time_stamp = (payload.has_key? 'time_stamp') ? payload['time_stamp'] : nil
    sender     = (message.has_key? 'fromUuid'  ) ? message['fromUuid']   : 'UNKNOWN'

    @dbaccess.write_to_log(2,"sender     = #{sender}")
    @dbaccess.write_to_log(2,"time_stamp = #{time_stamp}")

    if time_stamp != @last_time_stamp

      @last_time_stamp = time_stamp

      $bot_control.read_hw_status()

      return_message =
        {
          :message_type                   => 'read_status_response',
          :time_stamp                     => Time.now.to_f.to_s,
          :confirm_id                     => time_stamp,

          :status                         => $bot_control.info_status,
          :status_time_local              => Time.now,
          :status_nr_msg_received         => $info_nr_msg_received,
          :status_movement                => $bot_control.info_movement,
          :status_last_command_executed   => $bot_control.info_command_last,
          :status_next_command_scheduled  => $bot_control.info_command_next,
          :status_nr_of_commands_executed => $bot_control.info_nr_of_commands,
          :status_current_x               => $bot_control.info_current_x,
          :status_current_y               => $bot_control.info_current_y,
          :status_current_z               => $bot_control.info_current_z,
          :status_target_x                => $bot_control.info_target_x,
          :status_target_y                => $bot_control.info_target_y,
          :status_target_z                => $bot_control.info_target_z,
          :status_end_stop_x_a            => $bot_control.info_end_stop_x_a,
          :status_end_stop_x_b            => $bot_control.info_end_stop_x_b,
          :status_end_stop_y_a            => $bot_control.info_end_stop_y_a,
          :status_end_stop_y_b            => $bot_control.info_end_stop_y_b,
          :status_end_stop_z_a            => $bot_control.info_end_stop_z_a,
          :status_end_stop_z_b            => $bot_control.info_end_stop_z_b
        }

       @dbaccess.write_to_log(2,"return_message = #{return_message}")

       $skynet.send_message(sender, return_message)

    end
  end

  # Read logs from database and send through skynet
  #
  def read_logs(message)

    @dbaccess.write_to_log(2,'handle read logs')

    payload = message['payload']
    
    time_stamp = (payload.has_key? 'time_stamp') ? payload['time_stamp'] : nil
    sender     = (message.has_key? 'fromUuid'  ) ? message['fromUuid']   : 'UNKNOWN'

    @dbaccess.write_to_log(2,"sender     = #{sender}")
    @dbaccess.write_to_log(2,"time_stamp = #{time_stamp}")

    if time_stamp != @last_time_stamp

      @last_time_stamp = time_stamp

      logs = @dbaccess.read_logs_all()

      log_list = Array.new
      logs.each do |log|
        item =
        {
          'text'   => log.text,
          'module' => log.module_id,
          'time'   => log.created_at
        }
        log_list << item
      end

      return_message =
        {
          :message_type => 'read_logs_response',
          :time_stamp   => Time.now.to_f.to_s,
          :confirm_id   => time_stamp,
          :logs         => log_list
        }

      $skynet.send_message(sender, return_message)

    end    
  end

  # Read parameter list from the database and send through skynet
  #
  def read_parameters(message)

    @dbaccess.write_to_log(2,'handle read parameters')

    payload = message['payload']
    
    time_stamp = (payload.has_key? 'time_stamp') ? payload['time_stamp'] : nil
    sender     = (message.has_key? 'fromUuid'  ) ? message['fromUuid']   : 'UNKNOWN'

    @dbaccess.write_to_log(2,"sender     = #{sender}")
    @dbaccess.write_to_log(2,"time_stamp = #{time_stamp}")

    if time_stamp != @last_time_stamp

      @last_time_stamp = time_stamp

      param_list = @dbaccess.read_parameter_list()

      return_message =
        {
          :message_type => 'read_parameters_response',
          :time_stamp   => Time.now.to_f.to_s,
          :confirm_id   => time_stamp,
          :parameters   => param_list
        }

      @dbaccess.write_to_log(2,"reply = #{return_message}")


      $skynet.send_message(sender, return_message)

    end    
  end

  # Write parameters in list from skynet to the database
  #
  def write_parameters(message)

    @dbaccess.write_to_log(2,'handle write parameters')

    payload = message['payload']
    
    time_stamp = (payload.has_key? 'time_stamp') ? payload['time_stamp'] : nil
    sender     = (message.has_key? 'fromUuid'  ) ? message['fromUuid']   : 'UNKNOWN'

    #@dbaccess.write_to_log(2,"sender = #{sender}")

    if time_stamp != @last_time_stamp
      @last_time_stamp = time_stamp

      if payload.has_key? 'parameters'
      
        param_list = payload['parameters']
        param_list.each do |param|

          if param.has_key? 'name' and param.has_key? 'type' and param.has_key? 'value' 

            @dbaccess.write_to_log(2,"param = #{param}")

            name  = param['name' ]
            type  = param['type' ]
            value = param['value']

            @dbaccess.write_to_log(2,"name = #{name}")
            @dbaccess.write_to_log(2,"type  = #{type}")
            @dbaccess.write_to_log(2,"value = #{value}")
            @dbaccess.write_parameter_with_type(name, type, value)

          end
        end
        send_confirmation(sender, time_stamp)
      else
        send_error(sender, time_stamp, 'no paramer list in message')                           
      end      
    end
  end

  def single_command(message)

    @dbaccess.write_to_log(2,'handle single command')

    payload = message['payload']
    
    time_stamp = (payload.has_key? 'time_stamp') ? payload['time_stamp'] : nil
    sender     = (message.has_key? 'fromUuid'  ) ? message['fromUuid']   : 'UNKNOWN'

    @dbaccess.write_to_log(2,"sender = #{sender}")

    if time_stamp != @last_time_stamp
      @last_time_stamp = time_stamp

      if payload.has_key? 'command' 

        command = payload['command']

        # send the command to the queue
        delay  = command['delay']
        action = command['action']
        x      = command['x']
        y      = command['y']
        z      = command['z']
        speed  = command['speed']
        amount = command['amount']
        delay  = command['delay']

        @dbaccess.write_to_log(2,"[#{action}] x: #{x}, y: #{y}, z: #{z}, speed: #{speed}, amount: #{amount} delay: #{delay}")
        @dbaccess.create_new_command(Time.now + delay.to_i,'single_command')
        @dbaccess.add_command_line(action, x.to_i, y.to_i, z.to_i, speed.to_s, amount.to_i)
        @dbaccess.save_new_command

        @dbaccess.write_to_log(2,'sending comfirmation')

        $skynet.confirmed = false

        send_confirmation(sender, time_stamp)

      else

        @dbaccess.write_to_log(2,'no command in message')
        @dbaccess.write_to_log(2,'sending error')

        $skynet.confirmed = false
        send_error(sender, time_stamp, 'no command in message')

      end

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

  def send_confirmation(destination, time_stamp)
    command =
      {
        :message_type => 'confirmation',
        :time_stamp   => Time.now.to_f.to_s,
        :confirm_id   => time_stamp
      }
    $skynet.send_message(destination, command)
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
    $skynet.send_message(destination, command)
  end

end
