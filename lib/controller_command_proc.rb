# FarmBot Controller command processor
# processes the comamdn and calles the right function in the hardware class

class ControllerCommandProc

  def initialize
    @bot_dbaccess        = $bot_dbaccess
  end

  def whitelist
    ['move_absolute','move_relative','home_x','home_y','home_z','calibrate_x','calibrate_y','calibrate_z','dose_water','set_speed','pin_write','pin_read','pin_mode','pin_pulse','servo_move']
  end

  def check_whitelist(function)
    raise "UNAUTHORIZED" unless whitelist.include?(function.upcase)
  end

  def process_command( cmd )

    if cmd != nil
      cmd.command_lines.each do |command_line|
        #$status.info_movement = "#{command_line.action.downcase} xyz=#{command_line.coord_x} #{command_line.coord_y} #{command_line.coord_z} amt=#{command_line.amount} spd=#{command_line.speed}"
        @bot_dbaccess.write_to_log(1,@info_movement)
        send_command(command_line)
      end
    else
      sleep 0.1
    end

    $status.info_movement = 'idle'

  end

  def send_command(command_line)
    if $hardware_sim == 0
      function = command_line.action.downcase.sub(' ','_')
      #puts function
      check_whitelist(function)
      send(function, command_line)
    else
      @bot_dbaccess.write_to_log(1,'>simulating hardware<')
      sleep 2
    end
  end

  def move_absolute(command_line)
    $bot_hardware.move_absolute(command_line.coord_x, command_line.coord_y, command_line.coord_z)
  end

  def move_relative(command_line)
    $bot_hardware.move_relative(command_line.coord_x, command_line.coord_y, command_line.coord_z)
  end

  def home_x(command_line)
    $bot_hardware.move_home_x
  end

  def home_y(command_line)
    $bot_hardware.move_home_y
  end

  def home_z(command_line)
    $bot_hardware.move_home_z
  end

  def calibration_x(command_line)
    $bot_hardware.calibrate_x
  end

  def calibration_y(command_line)
    $bot_hardware.calibrate_y
  end

  def calibration_z(command_line)
    $bot_hardware.calibrate_z
  end

  def dose_water(command_line)
    #$bot_hardware.dose_water(command_line.amount)
  end

  def set_speed(command_line)
    $bot_hardware.set_speed(command_line.speed)
  end

  def pin_write(command_line)
    $bot_hardware.pin_std_set_value(command_line.pin_nr, command_line.pin_value_1, command_line.pin_mode)
  end

  def pin_read(command_line)
    $bot_hardware.pin_std_read_value(command_line.pin_nr, command_line.pin_mode, command_line.external_info)
  end

  def pin_mode(command_line)
    $bot_hardware.pin_std_set_mode(command_line.pin_nr, command_line.pin_mode)
  end

  def pin_pulse(command_line)
    $bot_hardware.pin_std_pulse(command_line.pin_nr, command_line.pin_value_1, 
                command_line.pin_value_2, command_line.pin_time, command_line.pin_mode)
  end

  def servo_move(command_line)
    $bot_hardware.servo_std_move(command_line.pin_nr, command_line.pin_value_1)
  end



end
