# FarmBot Controller Menu

require './lib/controller.rb'
require './lib/filehandler.rb'
require "./lib/hardware/ramps.rb"

$bot_control		= Control.new
$bot_hardware 		= HardwareInterface.new

$shutdown		= 0
#$command_queue		= Queue.new
#$command_finished	= Queue.new

# *thread disabled for now*
# Main loop for the bot. Keep cycling until quiting time
#bot_thread = Thread.new { 
#
#	bot = Control.new
#	while $shutdown == 0
#		bot.runCycle
#	end
#
#}

# just a little menu for testing

$move_size = 10

while $shutdown == 0 do

	#system('cls')
	#system('clear')
	
	puts '[FarmBot Controller Menu]'
	puts ''
	puts 'p - stop'
	puts 't - execute test file'
	puts ''
	puts "move size = #{$move_size}"
	puts ''
	puts 'w - forward'
	puts 's - back'
	puts 'a - left'
	puts 'd - right'
	puts 'r - up'
	puts 'f - down'
	puts ''
	puts 'z - home z axis'	
	puts 'x - home x axis'	
	puts 'c - home y axis'	
	puts ''
	puts 'q - step size'	
	puts ''
	print 'command > '
	input = gets
	puts ''
	
	case input.upcase[0]
		when "P" # Quit
			$shutdown = 1
			puts 'Shutting down...'
		when "O" # Get status
			puts 'Not implemented yet. Press \'Enter\' key to continue.'
			gets

		when "Q" # Set step size
			print 'Enter new step size > '
			move_size_temp = gets
			$move_size = move_size_temp.to_i if move_size_temp.to_i > 0
		when "T" # Execute test file
		
			# read the file
			new_command = TestFileHandler.readCommandFile
			new_command.commandid = 0
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_conrtol.setCommand(new_command)
		when "Z" # Move to home
		
			# create the command
			new_command = ControlCommand.new
			new_command.commandid = 0
			
			# add lines with the right actions to the command
			new_line = ControlCommandLine.new
			new_line.action = "HOME Z"
			new_command.lines = [new_line]
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_control.setCommand(new_command)
		when "X" # Move to home
		
			# create the command
			new_command = ControlCommand.new
			new_command.commandid = 0
			
			# add lines with the right actions to the command
			new_line = ControlCommandLine.new
			new_line.action = "HOME X"
			new_command.lines = [new_line]
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_control.setCommand(new_command)
		when "C" # Move to home
		
			# create the command
			new_command = ControlCommand.new
			new_command.commandid = 0
			
			# add lines with the right actions to the command
			new_line = ControlCommandLine.new
			new_line.action = "HOME Y"
			new_command.lines = [new_line]
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_control.setCommand(new_command)
		when "W" # Move forward
		
			# create the command
			new_command = ControlCommand.new
			new_command.commandid = 0
			
			# add lines with the right actions to the command
			new_line = ControlCommandLine.new
			new_line.action = "MOVE RELATIVE"
			new_line.xCoord = 0
			new_line.yCoord = $move_size
			new_line.zCoord = 0
			new_command.lines = [new_line]
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_control.setCommand(new_command)
		when "S" # Move back
		
			# create the command
			new_command = ControlCommand.new
			new_command.commandid = 0
			
			# add lines with the right actions to the command
			new_line = ControlCommandLine.new
			new_line.action = "MOVE RELATIVE"
			new_line.xCoord = 0
			new_line.yCoord = -$move_size
			new_line.zCoord = 0
			new_command.lines = [new_line]
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_control.setCommand(new_command)
		when "A" # Move left
		
			# create the command
			new_command = ControlCommand.new
			new_command.commandid = 0
			
			# add lines with the right actions to the command
			new_line = ControlCommandLine.new
			new_line.action = "MOVE RELATIVE"
			new_line.xCoord = -$move_size
			new_line.yCoord = 0
			new_line.zCoord = 0
			new_command.lines = [new_line]
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_control.setCommand(new_command)
		when "D" # Move right
		
			# create the command
			new_command = ControlCommand.new
			new_command.commandid = 0
			
			# add lines with the right actions to the command
			new_line = ControlCommandLine.new
			new_line.action = "MOVE RELATIVE"
			new_line.xCoord = $move_size
			new_line.yCoord = 0
			new_line.zCoord = 0
			new_command.lines = [new_line]
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_control.setCommand(new_command)
		when "R" # Move up
		
			# create the command
			new_command = ControlCommand.new
			new_command.commandid = 0
			
			# add lines with the right actions to the command
			new_line = ControlCommandLine.new
			new_line.action = "MOVE RELATIVE"
			new_line.xCoord = 0
			new_line.yCoord = 0
			new_line.zCoord = $move_size
			new_command.lines = [new_line]
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_control.setCommand(new_command)
		when "F" # Move down
		
			# create the command
			new_command = ControlCommand.new
			new_command.commandid = 0
			
			# add lines with the right actions to the command
			new_line = ControlCommandLine.new
			new_line.action = "MOVE RELATIVE"
			new_line.xCoord = 0
			new_line.yCoord = 0
			new_line.zCoord = -$move_size
			new_command.lines = [new_line]
			
			# put the command into the queue for execution
			#$command_queue << new_command
			$bot_control.setCommand(new_command)
		end

	$bot_control.runCycle
	
end
