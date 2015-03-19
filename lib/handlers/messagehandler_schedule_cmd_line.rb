require './lib/database/dbaccess.rb'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerScheduleCmdLine

  attr_accessor :delay, :action, :x, :y, :z, :speed, :amount, :delay, :pin_nr,
    :pin_value1, :pin_value2, :pin_mode, :pin_time, :ext_info

  def initialize
    @dbaccess = DbAccess.current
  end


  def split_command_line(command)
    @delay      = command['delay'] || 0
    @action     = command['action'] || 'NOP'
    @x          = command['x'] || 0
    @y          = command['y'] || 0
    @z          = command['z'] || 0
    @speed      = command['speed'] || 0
    @amount     = command['amount'] || 0
    @delay      = command['delay'] || 0
    @pin_nr     = command['pin'] || 0
    @pin_value1 = command['value1'] || 0
    @pin_value2 = command['value2'] || 0
    @pin_mode   = command['mode'] || 0
    @pin_time   = command['time'] || 0
    @ext_info   = command['info'] || 0
  end

  def write_to_log
      @dbaccess.write_to_log(2,"[#{@action}] x: #{@x}, y: #{@y}, z: #{@z}, speed: #{@speed}, amount: #{@amount} delay: #{@delay}")
      @dbaccess.write_to_log(2,"[#{@action}] pin_nr: #{@pin_nr}, value1: #{@pin_value1}, value2: #{@pin_value2}, mode: #{@pin_mode}")
      @dbaccess.write_to_log(2,"[#{@action}] ext_info: #{@ext_info}")
  end

end
