
# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandlerMessage

  attr_accessor :sender, :time_stamp, :message_type, :payload
  attr_accessor :handled, :handler, :delay

  def initialize
    handled = false
  end

  # Handle the message received from skynet
  #
  def handle_message(message)
    if authorized?(message)
      self.send(translate_action_name(message), message)
      message.handled = true
    end
  end

  # Ensure that the attempted command is allowed and also implemented.
  def authorized?(message)
    cmd = translate_action_name(message)
    is_command = ControllerCommandProc::WHITELIST.include?(cmd)
    is_method  = self.respond_to?(cmd)
    is_command && is_method
  end

  # PROBLEM: There are numerous spelling of commands and names for commands
  # throughout the application. Sometimes it is move_rel, other times it is
  # "MOVE RELATIVE". Sometimes we call it a message, other times an action.
  # This method is a quick fix. Maybe we should make a uniform naming convention
  def translate_action_name(message)
    (message.payload["command"]["action"] || '').downcase.gsub(' ', '_')
  end

  def move_absolute(*)
    raise 'Not implemented yet.'
  end

  def move_relative(message)
    inputs = message.payload["command"] || {}
    # {"action"=>"MOVE RELATIVE", "x"=>0, "y"=>0, "z"=>0, "speed"=>100, "delay"=>0}
    args = [
      'MOVE RELATIVE', # action
      inputs['x'] || 0, # x
      inputs['y'] || 0, # y
      inputs['z'] || 0, # z
      inputs['speed'] || 100, # speed
      0, # amount
      0, # pin_nr
      0, # value1
      0, # value2
      0, # mode
      0, # time
      0, # external_info
    ]
    $bot_dbaccess.create_new_command(Time.now,'menu')
    $bot_dbaccess.add_command_line(*args)
    $bot_dbaccess.save_new_command
    $bot_dbaccess.increment_refresh
  rescue => e
    puts e.message, e.backtrace.first
  end

  def home_x(*)
    raise 'Not implemented yet.'
  end

  def home_y(*)
    raise 'Not implemented yet.'
  end

  def home_z(*)
    raise 'Not implemented yet.'
  end

  def calibrate_x(*)
    raise 'Not implemented yet.'
  end

  def calibrate_y(*)
    raise 'Not implemented yet.'
  end

  def calibrate_z(*)
    raise 'Not implemented yet.'
  end

  def dose_water(*)
    raise 'Not implemented yet.'
  end

  def set_speed(*)
    raise 'Not implemented yet.'
  end

  def pin_write(*)
    raise 'Not implemented yet.'
  end

  def pin_read
    raise 'Not implemented yet.'
  end

  def pin_mode
    raise 'Not implemented yet.'
  end

  def pin_pulse
    raise 'Not implemented yet.'
  end

  def servo_move
    raise 'Not implemented yet.'
  end
end
