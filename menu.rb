puts '[FarmBot Controller Menu]'
puts 'starting up'

require './lib/dbaccess.rb'
require './lib/filehandler.rb'

require './lib/controller.rb'
#require "./lib/hardware/ramps.rb"

#$bot_control		= Control.new
#$bot_hardware 		= HardwareInterface.new

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

puts 'connecting to database'

$bot_dbaccess = DbAccess.new

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
			#$bot_conrtol.setCommand(new_command)
		when "Z" # Move to home
			$bot_dbaccess.createNewCommand(Time.now)
			$bot_dbaccess.addCommandLine('HOME Z', 0, 0, 0, 0, 0)
			$bot_dbaccess.saveNewCommand
		when "X" # Move to home
			$bot_dbaccess.createNewCommand(Time.now)
			$bot_dbaccess.addCommandLine('HOME X', 0, 0, 0, 0, 0)
			$bot_dbaccess.saveNewCommand
		when "C" # Move to home
			$bot_dbaccess.createNewCommand(Time.now)
			$bot_dbaccess.addCommandLine('HOME Y',0 ,0 ,-$move_size, 0, 0)
			$bot_dbaccess.saveNewCommand
		when "W" # Move forward
			$bot_dbaccess.createNewCommand(Time.now)
			$bot_dbaccess.addCommandLine('MOVE RELATIVE',0,$move_size, 0, 0, 0)
			$bot_dbaccess.saveNewCommand
		when "S" # Move back
			$bot_dbaccess.createNewCommand(Time.now)
			$bot_dbaccess.addCommandLine('MOVE RELATIVE',0,-$move_size, 0, 0, 0)
			$bot_dbaccess.saveNewCommand
		when "A" # Move left
			$bot_dbaccess.createNewCommand(Time.now)
			$bot_dbaccess.addCommandLine('MOVE RELATIVE', -$move_size, 0, 0, 0, 0)
			$bot_dbaccess.saveNewCommand
		when "D" # Move right
			$bot_dbaccess.createNewCommand(Time.now)
			$bot_dbaccess.addCommandLine('MOVE RELATIVE', $move_size, 0, 0, 0, 0)
			$bot_dbaccess.saveNewCommand
		when "R" # Move up
			$bot_dbaccess.createNewCommand(Time.now)
			$bot_dbaccess.addCommandLine('MOVE RELATIVE', 0, 0, $move_size, 0, 0)
			$bot_dbaccess.saveNewCommand
		when "F" # Move down		
			$bot_dbaccess.createNewCommand(Time.now)
			$bot_dbaccess.addCommandLine("MOVE RELATIVE", 0, 0, -$move_size, 0, 0)
			$bot_dbaccess.saveNewCommand
		end

end

			
