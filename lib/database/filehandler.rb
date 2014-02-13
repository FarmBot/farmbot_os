
# read the test file and convert it into one command

require './lib/controlcommand'

class TestFileHandler
	
	def self.readCommandFile
		if File.file?('testcommands.csv')
			$bot_dbaccess.createNewCommand(Time.now)
			f = File.open('testcommands.csv','r')
			f.each_line do |line|
				if line.length > 5
					#cmd_line = ControlCommandLine.new
					#cmd_line.parseText( line )
					#cmd.lines << cmd_line
					params = line.split(',')
					action = params[0].to_s
					xCoord = params[1].to_i
					yCoord = params[2].to_i
					zCoord = params[3].to_i
					$bot_dbaccess.addCommandLine('HOME Z', 0, 0, 0, 0, 0)

				end
			end
			$bot_dbaccess.saveNewCommand
		end
	end
end
