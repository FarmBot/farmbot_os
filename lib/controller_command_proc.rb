# FarmBot Controller command processor
# processes the comamdn and calles the right function in the hardware class

class ControllerCommandProc

  def initialize
    @bot_dbaccess        = $bot_dbaccess
  end

  def process_command( cmd )

    if cmd != nil
      cmd.command_lines.each do |command_line|
        $status.info_movement = "#{command_line.action.downcase} xyz=#{command_line.coord_x} #{command_line.coord_y} #{command_line.coord_z} amt=#{command_line.amount} spd=#{command_line.speed}"
        @bot_dbaccess.write_to_log(1,@info_movement)

        if $hardware_sim == 0
          case command_line.action.upcase
            when "MOVE ABSOLUTE"
              $bot_hardware.move_absolute(command_line.coord_x, command_line.coord_y, command_line.coord_z)
            when "MOVE RELATIVE"
              $bot_hardware.move_relative(command_line.coord_x, command_line.coord_y, command_line.coord_z)
            when "HOME X"
              $bot_hardware.move_home_x
            when "HOME Y"
              $bot_hardware.move_home_y
            when "HOME Z"
              $bot_hardware.move_home_z

            when "CALIBRATE X"
              $bot_hardware.calibrate_x
            when "CALIBRATE Y"
              $bot_hardware.calibrate_y
            when "CALIBRATE Z"
              $bot_hardware.calibrate_z

            when "DOSE WATER"
              #$bot_hardware.dose_water(command_line.amount)
            when "SET SPEED"
              $bot_hardware.set_speed(command_line.speed)
            when "PIN WRITE"
              $bot_hardware.pin_std_set_value(command_line.pin_nr, command_line.pin_value_1, command_line.pin_mode)
            when "PIN READ"
              $bot_hardware.pin_std_read_value(command_line.pin_nr, command_line.pin_mode, command_line.external_info)
            when "PIN MODE"
              $bot_hardware.pin_std_set_mode(command_line.pin_nr, command_line.pin_mode)
            when "PIN PULSE"
              $bot_hardware.pin_std_pulse(command_line.pin_nr, command_line.pin_value_1, 
                command_line.pin_value_2, command_line.pin_time, command_line.pin_mode)

            when "SERVO MOVE"
              $bot_hardware.servo_std_move(command_line.pin_nr, command_line.pin_value_1)

          end

        else
          @bot_dbaccess.write_to_log(1,'>simulating hardware<')

          sleep 2
        end
      end
    else
      sleep 0.1
    end

    $status.info_movement = 'idle'

  end
end
