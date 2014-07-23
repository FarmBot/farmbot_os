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

    @bot_dbaccess        = $bot_dbaccess
  end

  def runFarmBot
    @info_status = 'starting'
    #show_info()

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

              refresh_received = @bot_dbaccess.check_refresh
              #puts 'refresh received' if refresh_received != false

            end

          end

        else

          @info_status = 'no command found, waiting'
          #show_info()

          @info_command_next = nil

          refresh_received = false
          wait_start_time = Time.now

          # wait for a minute or until a refresh it set in the database as a sign
          # new data has arrived

          while  Time.now < wait_start_time + 60 and refresh_received == false

            sleep 1
            #show_info()

            refresh_received = @bot_dbaccess.check_refresh
            #puts 'refresh received' if refresh_received != false

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
        #show_info()
        @bot_dbaccess.write_to_log(1,@info_movement)

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
          end

          read_hw_status()

          @info_target_x  = @info_current_x
          @info_target_y  = @info_current_y
          @info_target_z  = @info_current_z

        else
          #puts ''
          #puts '>simulating hardware<'
          #puts ''

          @bot_dbaccess.write_to_log(1,'>simulating hardware<')

          sleep 2
        end
      end
    else
      sleep 0.1
    end

    @info_movement = 'idle'
    #show_info()

  end

  def read_hw_status()
    @info_current_x    = $bot_hardware.axis_x_pos
    @info_current_y    = $bot_hardware.axis_x_pos
    @info_current_z    = $bot_hardware.axis_x_pos
    @info_end_stop_x_a = $bot_hardware.axis_x_end_stop_a
    @info_end_stop_x_b = $bot_hardware.axis_x_end_stop_b
    @info_end_stop_y_a = $bot_hardware.axis_y_end_stop_a
    @info_end_stop_y_b = $bot_hardware.axis_y_end_stop_b
    @info_end_stop_z_a = $bot_hardware.axis_z_end_stop_a
    @info_end_stop_z_b = $bot_hardware.axis_z_end_stop_b
  end

  def show_info

    system('clear')

    #puts '   /\    '
    #puts '---------'
    #puts ' FarmBot '
    #puts '---------'
    #puts '   \/    '
    #puts ''

    #puts '[scheduling]'
    puts "current time            = #{Time.now}"
    puts "uuid                    = #{$info_uuid}"
    puts "token                   = #{$info_token}"
    puts "last msg received       = #{$info_last_msg_received}"
    puts "nr msg received         = #{$info_nr_msg_received}"
    puts "status                  = #{$bot_control.info_status}"
    puts "movement                = #{$bot_control.info_movement}"
    puts "last command executed   = #{$bot_control.info_command_last}"
    puts "next command scheduled  = #{$bot_control.info_command_next}"
    puts "nr of commands executed = #{$bot_control.info_nr_of_commands}"

  end

end
