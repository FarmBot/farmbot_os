require 'FarmBotControlInterface'

# specific implementation to control the bot using marlin software on arduino and G-Code

class FarmBotControlInterface < FarmBotControlInterfaceAbstract
	
	def initialize
		#serialPort = ...
	end
	
	def moveTo( X, Y, Z )
		#serialPort.Send("G21 X#{X} Y#{Y} Z#{Z}")
	end
	
	def moveHome
		#serialPort.Send("G20")
	end
	
	def setSpeed( speed )
	end
end

