
require 'date'
require_relative 'database/dbaccess'

# FarmBot Controller: This module executes the schedule. It reades the next
# command and sends it to the hardware implementation
class Controller

  # read command from schedule, wait for execution time

  def initialize

    @bot_dbaccess = DbAccess.new
  end

  def runFarmBot

    check = @bot_dbaccess.check_refresh

    while $shutdown == 0 do

      # keep checking the database for new data

      puts 'checking schedule'
      command = @bot_dbaccess.get_command_to_execute
      @bot_dbaccess.save_refresh

      if command != nil

        puts "command retrieved is scheduled for #{command.scheduled_time}"
        puts "curent time is #{Time.now}"

        #scheduled_time = command.scheduled_time

        if command.scheduled_time <= Time.now or command.scheduled_time == nil

          # execute the command now and set the status to done
          puts 'execute command'

          process_command( command )
          @bot_dbaccess.set_command_to_execute_status('FINISHED')

        else

          puts 'wait for scheduled time or refresh'

          refresh_received = false

          wait_start_time = Time.now

          # wait until the scheduled time has arrived, or wait for a minute or 
          #until a refresh it set in the database as a sign new data has arrived

          while Time.now < wait_start_time + 60 and command.scheduled_time > Time.now - 1 and refresh_received == false

            sleep 1

            refresh_received = @bot_dbaccess.check_refresh
            puts 'refresh received' if refresh_received != false

          end

        end

      else

        puts 'no command found, wait'

        refresh_received = false
        wait_start_time = Time.now

        # wait for a minute or until a refresh it set in the database as a sign
        # new data has arrived

        while  Time.now < wait_start_time + 60 and refresh_received == false

          sleep 1

          refresh_received = @bot_dbaccess.check_refresh
          puts 'refresh received' if refresh_received != false

        end
      end
    end
  end

  def process_command( cmd )

    if cmd != nil
      cmd.commandlines.each do |command_line|
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
          when "SET SPEED"
            $bot_hardware.set_speed(command_line.speed)
        end
      end
    else
      sleep 0.1
    end
  end
end
