require 'active_record'
require 'date'
require_relative 'database/dbaccess'

# FarmBot Controller: This module executes the schedule. It reades the next
# command and sends it to the hardware implementation
class Controller

  # read command from schedule, wait for execution time
  attr_reader :info_command_next, :info_command_last, :info_nr_of_commands, :info_status, :info_movement
  attr_reader :info_current_x, :info_current_y, :info_current_z, :info_target_x, :info_target_y, :info_target_z
  attr_reader :info_end_stop_x_a, :info_end_stop_x_b  
  attr_reader :info_end_stop_y_a, :info_end_stop_y_b  
  attr_reader :info_end_stop_z_a, :info_end_stop_z_b  

  def initialize
    @info_command_next   = nil
    @info_command_last   = nil
    @info_nr_of_commands = 0
    @info_status         = 'initializing'
    @info_movement       = 'idle'
    @info_current_x      = 0
    @info_current_y      = 0
    @info_current_z      = 0
    @info_target_x       = 0
    @info_target_y       = 0
    @info_target_z       = 0
    @info_end_stop_x_a   = 0
    @info_end_stop_x_b   = 0
    @info_end_stop_y_a   = 0
    @info_end_stop_y_b   = 0
    @info_end_stop_z_a   = 0
    @info_end_stop_z_b   = 0

    @star_char           = 0

    @bot_dbaccess        = $bot_dbaccess
    @last_hw_check       = Time.now
  end

  def runFarmBot
    @info_status = 'starting'
    puts 'OK'
 
    print 'arduino         '
    sleep 1
    $bot_hardware.read_device_version()
    puts  $bot_hardware.device_version

    @info_status = 'synchronizing arduino parameters'
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

        @info_status = 'checking schedule'
        #show_info()

        command = @bot_dbaccess.get_command_to_execute
        @bot_dbaccess.save_refresh

        if command != nil

          @info_command_next = command.scheduled_time

          if command.scheduled_time <= Time.now or command.scheduled_time == nil

            # execute the command now and set the status to done
            @info_status = 'executing command'
            #show_info()

            @info_nr_of_commands = @info_nr_of_commands + 1

            process_command( command )
            @bot_dbaccess.set_command_to_execute_status('FINISHED')
            @info_command_last = Time.now
            @info_command_next = nil

          else

            @info_status = 'waiting for scheduled time or refresh'
            #show_info()

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

          @info_status = 'no command found, waiting'

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
      rescue Exception => e
        puts("Error in controller\n#{e.message}\n#{e.backtrace.inspect}")
        @bot_dbaccess.write_to_log(1,"Error in controller\n#{e.message}\n#{e.backtrace.inspect}")
      end
    end
  end

  def process_command( cmd )

    if cmd != nil
      cmd.command_lines.each do |command_line|
        @info_movement = "#{command_line.action.downcase} xyz=#{command_line.coord_x} #{command_line.coord_y} #{command_line.coord_z} amt=#{command_line.amount} spd=#{command_line.speed}"
        @bot_dbaccess.write_to_log(1,@info_movement)
puts @info_movement
        if $hardware_sim == 0
          case command_line.action.upcase
            when "MOVE ABSOLUTE"
              @info_target_x = command_line.coord_x
              @info_target_y = command_line.coord_y
              @info_target_z = command_line.coord_z
              $bot_hardware.move_absolute(command_line.coord_x, command_line.coord_y, command_line.coord_z)
            when "MOVE RELATIVE"
              @info_target_x = command_line.coord_x
              @info_target_y = command_line.coord_y
              @info_target_z = command_line.coord_z
              $bot_hardware.move_relative(command_line.coord_x, command_line.coord_y, command_line.coord_z)
            when "HOME X"
              @info_target_x = 0
              $bot_hardware.move_home_x
            when "HOME Y"
              @info_target_y = 0
              $bot_hardware.move_home_y
            when "HOME Z"
              @info_target_z = 0
              $bot_hardware.move_home_z
            when "DOSE WATER"
              $bot_hardware.dose_water(command_line.amount)
            when "SET SPEED"
              $bot_hardware.set_speed(command_line.speed)

            when "PIN WRITE"
              $bot_hardware.pin_std_set_value(command_line.pin_nr, command_line.pin_value_1)
            when "PIN READ"
              $bot_hardware.pin_std_read_value(command_line.pin_nr)
            when "PIN MODE"
              $bot_hardware.pin_std_set_mode(command_line.pin, command_line.pin_mode)
            when "PIN PULSE"
              $bot_hardware.pin_std_pulse(command_line.pin, command_line.pin_value_1, 
                command_line.pin_value_2, command_line.pin_time)
          end

          read_hw_status()

          @info_target_x  = @info_current_x
          @info_target_y  = @info_current_y
          @info_target_z  = @info_current_z

        else
          @bot_dbaccess.write_to_log(1,'>simulating hardware<')

          sleep 2
        end
      end
    else
      sleep 0.1
    end

    @info_movement = 'idle'

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

    @info_current_x    = $bot_hardware.axis_x_pos_conv
    @info_current_y    = $bot_hardware.axis_y_pos_conv
    @info_current_z    = $bot_hardware.axis_z_pos_conv

    @info_end_stop_x_a = $bot_hardware.axis_x_end_stop_a
    @info_end_stop_x_b = $bot_hardware.axis_x_end_stop_b
    @info_end_stop_y_a = $bot_hardware.axis_y_end_stop_a
    @info_end_stop_y_b = $bot_hardware.axis_y_end_stop_b
    @info_end_stop_z_a = $bot_hardware.axis_z_end_stop_a
    @info_end_stop_z_b = $bot_hardware.axis_z_end_stop_b

    print_hw_status()

  end

  def print_hw_status()

    100.times do
      print "\b"
    end

    print "x %04d %s%s " % [@info_current_x, bool_to_char(@info_end_stop_x_a), bool_to_char(@info_end_stop_x_b)]
    print "y %04d %s%s " % [@info_current_y, bool_to_char(@info_end_stop_y_a), bool_to_char(@info_end_stop_z_b)]
    print "z %04d %s%s " % [@info_current_z, bool_to_char(@info_end_stop_z_a), bool_to_char(@info_end_stop_z_b)]
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
