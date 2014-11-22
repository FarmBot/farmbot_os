# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerScheduleCmdLine

  attr_accessor       :delay
  attr_accessor       :action
  attr_accessor       :x
  attr_accessor       :y
  attr_accessor       :z
  attr_accessor       :speed
  attr_accessor       :amount
  attr_accessor       :delay

  attr_accessor       :pin_nr
  attr_accessor       :pin_value1
  attr_accessor       :pin_value2
  attr_accessor       :pin_mode
  attr_accessor       :pin_time
  attr_accessor       :ext_info

  def split_command_line(command)
    @delay      = (command.has_key? 'delay' ) ? command['delay'   ] : 0
    @action     = (command.has_key? 'action') ? command['action'  ] : 'NOP'
    @x          = (command.has_key? 'x'     ) ? command['x'       ] : 0
    @y          = (command.has_key? 'y'     ) ? command['y'       ] : 0 
    @z          = (command.has_key? 'z'     ) ? command['z'       ] : 0  
    @speed      = (command.has_key? 'speed' ) ? command['speed'   ] : 0
    @amount     = (command.has_key? 'amount') ? command['amount'  ] : 0
    @delay      = (command.has_key? 'delay' ) ? command['delay'   ] : 0

    @pin_nr     = (command.has_key? 'pin')    ? command['pin'     ] : 0
    @pin_value1 = (command.has_key? 'value1') ? command['value1'  ] : 0
    @pin_value2 = (command.has_key? 'value2') ? command['value2'  ] : 0
    @pin_mode   = (command.has_key? 'mode'  ) ? command['mode'    ] : 0
    @pin_time   = (command.has_key? 'time'  ) ? command['time'    ] : 0
    @ext_info   = (command.has_key? 'info'  ) ? command['info'    ] : 0
  end

  def log_command_line
      $dbaccess.write_to_log(2,"[#{@action}] x: #{@x}, y: #{@y}, z: #{@z}, speed: #{@speed}, amount: #{@amount} delay: #{@delay}")
      $dbaccess.write_to_log(2,"[#{@action}] pin_nr: #{@pin_nr}, value1: #{@pin_value1}, value2: #{@pin_value2}, mode: #{@pin_mode}")
      $dbaccess.write_to_log(2,"[#{@action}] ext_info: #{@ext_info}")
  end

end
