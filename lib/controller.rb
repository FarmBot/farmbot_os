# FarmBot Controller

#require "Rubygems"
#require "FarmBotDbAccess"
#require "./hardware/ramps.rb"

require './lib/controlcommand.rb'
require './lib/filehandler.rb'

# This module ties the different components for the FarmBot together
# It reads the next action from the database, executes it and reports back
# and it will initiate the synchronization with the web systems

class Control

	def initialize	
		@inactiveCounter 	= 0
		@new_command		= nil
	end
	
	def setCommand( cmd )
		@new_command = cmd
	end

	def runCycle

		#if $command_queue.empty? == false
		if @new_command != nil

			#command = $command_queue.pop
			#command = @new_command
			#@new_command = nil
			@new_command.lines.each do |command_line|
			#command.lines.each do |command_line|
				case command_line.action.upcase
					when "MOVE ABSOLUTE"
						$bot_hardware.moveAbsolute(command_line.xCoord, command_line.yCoord, command_line.zCoord)
					when "MOVE RELATIVE"
						$bot_hardware.moveRelative(command_line.xCoord, command_line.yCoord, command_line.zCoord)
					when "HOME X"
						$bot_hardware.moveHomeX
					when "HOME Y"
						$bot_hardware.moveHomeY
					when "HOME Z"
						$bot_hardware.moveHomeZ
					when "SET SPEED"
						$bot_hardware.setSpeed(command_line.speed)
					when "SHUTDOWN"
						puts "shutdown"
						$shutdown = 1
				end

			end			
			#$commandFinished << command if command.commandid != nil and command.commandid > 0
		else
			sleep 0.1
		end

		@new_command = nil
		
	end
end

#$bot_hardware 		= FarmBotControlInterface.new
#$command_queue		= Queue.new
#$command_finished	= Queue.new
