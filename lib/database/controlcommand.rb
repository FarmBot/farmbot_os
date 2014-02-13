# command message class that is put into the queue to execute by the farmbot

class ControlCommand

	def initialize
		commandid = "NOP"
	end

	attr_accessor :lines, :commandid
end

class ControlCommandLine
	attr_accessor :action
	attr_accessor :xCoord, :xHome
	attr_accessor :yCoord, :yHome
	attr_accessor :zCoord, :zHome
	attr_accessor :quantity, :speed	

	def parseText( text )
		params = text.split(',')
		@action = params[0].to_s
		@xCoord = params[1].to_i
		@yCoord = params[2].to_i
		@zCoord = params[3].to_i
	end
end
