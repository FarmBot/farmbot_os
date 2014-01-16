# FarmBot schedule keeper

# Get commands from the database and execute them on the hardware

require 'date'

#require './lib/dbaccess.rb'
require './lib/controller.rb'
#require './lib/filehandler.rb'
#require "./lib/hardware/ramps.rb"

class Scheduler

  def runFarmBot

    check = $bot_dbaccess.checkRefresh      

    while $shutdown == 0 do

      # keep checking the database for new data

      puts 'checking schedule'
      command = $bot_dbaccess.getCommandToExecute
      $bot_dbaccess.saveRefresh      

      if command != nil

        puts "command retrieved is scheduled for #{command.scheduled_time}"
        puts "curent time is #{Time.now}"

        #scheduled_time = command.scheduled_time

        if command.scheduled_time <= Time.now or command.scheduled_time == nil

          # execute the command now and set the status to done
          puts 'execute command'
          
          $bot_control.setCommand( command )
          $bot_control.runCycle
          $bot_dbaccess.setCommandToExecuteStatus('FINISHED')

        else

          puts 'wait for scheduled time or refresh'

          refresh_received = false

          wait_start_time = Time.now

          # wait until the scheduled time has arrived, or wait for a minute or until a refresh it set in the database as a sign new data has arrived

          while Time.now < wait_start_time and command.scheduled_time > Time.now - 1 and refresh_received == false

            sleep 1

            refresh_received = $bot_dbaccess.checkRefresh
            puts 'refresh received' if refresh_received != false

          end

        end

      else

        puts 'no command found, wait'

        refresh_received = false
        wait_start_time = Time.now

        # wait for a minute or until a refresh it set in the database as a sign new data has arrived

        while  Time.now < wait_start_time + 60 and refresh_received == false

          sleep 1

          refresh_received = $bot_dbaccess.checkRefresh
          puts 'refresh received' if refresh_received != false

        end
      end
    end
  end
end
