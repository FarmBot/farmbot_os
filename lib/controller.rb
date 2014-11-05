require 'active_record'
require 'date'
require_relative 'database/dbaccess'

# FarmBot Controller: This module executes the schedule. It reades the next
# command and sends it to the hardware implementation
class Controller

  def initialize
    @star_char           = 0

    @bot_dbaccess        = $bot_dbaccess
    @last_hw_check       = Time.now
  end

  def runFarmBot
    $status.info_status = 'starting'
    puts 'OK'
 
    print 'arduino         '
    sleep 1
    $bot_hardware.read_device_version()
    puts  $bot_hardware.device_version

    $status.info_status = 'synchronizing arduino parameters'
    print 'parameters      '
    $bot_hardware.check_parameters    
    $bot_hardware.check_parameters

    if $bot_hardware.params_in_sync
      puts 'OK'
    else
      puts 'ERROR'
    end


    #$bot_hardware.read_end_stops()
    #$bot_hardware.read_postition()
    read_hw_status()

    @bot_dbaccess.write_to_log(1,'Controller running')
    check = @bot_dbaccess.check_refresh

    while $shutdown == 0 do

      begin

        # keep checking the database for new data

        if $status.emergency_stop == false

          $status.info_status = 'checking schedule'
          #show_info()

          command = @bot_dbaccess.get_command_to_execute
          @bot_dbaccess.save_refresh

        end

        if command != nil and $status.emergency_stop == false

          $status.info_command_next = command.scheduled_time

          if command.scheduled_time <= Time.now or command.scheduled_time == nil

            # execute the command now and set the status to done
            $status.info_status = 'executing command'
            #show_info()

            $status.info_nr_of_commands = $status.info_nr_of_commands + 1

            process_command( command )
            @bot_dbaccess.set_command_to_execute_status('FINISHED')
            $status.info_command_last = Time.now
            $status.info_command_next = nil

          else

            $status.info_status = 'waiting for scheduled time or refresh'

            refresh_received = false

            wait_start_time = Time.now

            # wait until the scheduled time has arrived, or wait for a minute or 
            #until a refresh it set in the database as a sign new data has arrived

            while Time.now < wait_start_time + 60 and command.scheduled_time > Time.now - 1 and refresh_received == false

              sleep 0.2

              check_hardware()

              refresh_received = @bot_dbaccess.check_refresh

            end

          end

        else

          if $status.emergency_stop == false

            $status.info_status = 'emergency stop'
            sleep 0.5
            check_hardware()

          else

            $status.info_status = 'no command found, waiting'

            @info_command_next = nil

            refresh_received = false
            wait_start_time = Time.now

            # wait for a minute or until a refresh it set in the database as a sign
            # new data has arrived

            while  Time.now < wait_start_time + 60 and refresh_received == false

              sleep 0.2

              check_hardware()

              refresh_received = @bot_dbaccess.check_refresh

            end
          end
        end
      rescue Exception => e
        puts("Error in controller\n#{e.message}\n#{e.backtrace.inspect}")
        @bot_dbaccess.write_to_log(1,"Error in controller\n#{e.message}\n#{e.backtrace.inspect}")
      end
    end
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

          read_hw_status()

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

  def check_hardware()
    if (Time.now - @last_hw_check) > 0.5
      $bot_hardware.check_parameters
      $bot_hardware.read_end_stops()
      $bot_hardware.read_postition()
      read_hw_status()
      @last_hw_check = Time.now

      print_star()
    end
  end

  def read_hw_status()

    print_hw_status()

  end

  def print_hw_status()

    100.times do
      print "\b"
    end

    print "x %04d %s%s " % [$status.info_current_x, bool_to_char($status.info_end_stop_x_a), bool_to_char($status.info_end_stop_x_b)]
    print "y %04d %s%s " % [$status.info_current_y, bool_to_char($status.info_end_stop_y_a), bool_to_char($status.info_end_stop_y_b)]
    print "z %04d %s%s " % [$status.info_current_z, bool_to_char($status.info_end_stop_z_a), bool_to_char($status.info_end_stop_z_b)]
    print ' '

  end

  def bool_to_char(value)
    if value
      return '*'
    else
      return '-'
    end
  end

  def print_star
    @star_char += 1
    @star_char %= 4
    print "\b"

    if $status.emergency_stop == true
      print 'E'
    else
      case @star_char
      when 0
        print '-'
      when 1
        print '\\'
      when 2
        print '|'
      when 3
        print '/'
      end
    end
  end

end
