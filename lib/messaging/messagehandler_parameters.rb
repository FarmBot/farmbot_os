require 'json'
require './lib/database/dbaccess.rb'
require 'time'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerParameter

  attr_accessor :message

  ## general handling messages

  def initialize
    @dbaccess = DbAccess.new
    @last_time_stamp  = ''
  end

  # A list of MessageHandler methods (as strings) that a Skynet User may access.
  #
  def whitelist
    ["read_parameters","write_parameters"]
  end

  # Handle the message received from skynet
  #
  # Handle the message received from skynet
  #
  def handle_message(message)

    handled = false

    if whitelist.include?(message.message_type)
      self.send(message)
      handled = true
    end

    handled
  end

  # Handles an error (typically, an unauthorized or unknown message). Returns
  # Hash.
  def error
    return {error: ""}
  end

  # Read parameter list from the database and send through skynet
  #
  def read_parameters(message)

    @dbaccess.write_to_log(2,'handle read parameters')

    param_list = @dbaccess.read_parameter_list()

    return_message =
      {
        :message_type => 'read_parameters_response',
        :time_stamp   => Time.now.to_f.to_s,
        :confirm_id   => time_stamp,
          :parameters   => param_list
      }

    @dbaccess.write_to_log(2,"reply = #{return_message}")


    message.handler.send_message(sender, return_message)

  end

  # Write parameters in list from skynet to the database
  #
  def write_parameters(message)

    @dbaccess.write_to_log(2,'handle write parameters')

    if message.payload.has_key? 'parameters'
      
      param_list = message.payload['parameters']
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
