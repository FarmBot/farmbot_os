# FarmBot schedule 

# This module reads the schedule from the mongodb. If a scheduled event is found, send the actions to the bot.

require "Rubygems"

# a few database classes

class FarmBotSchedule
	include MongoMapper::Document

	many	:BotScheduleActions

	# BotScheduleId		: unique id used to synchronize with cloud
	# CropId			: unique id used to synchronize with cloud
	# TimeScheduled		: time to start executing the actions
	# TimeExecuted		: time when actions are executed
	# Status			: a three letter status
	#						SYN	: synchronizing
	#						RTS	: ready to start
	#						STA	: started
	#						ERR	: error
	#						DNE	: done
	#						RPT : reported back to the cloud
end

class FarmBotScheduleAction

	include MongoMapper::EmbeddedDocument
	
	belongs_to	:botschedule
	
	# Action		: representation of the action to do
	#					MOV	: move to x, y, z
	#					SPD	: set speed
	#					SHD	: shutdown bot
	#					SSD	: set synchronization speed with cloud
	#					also needed later on: inject seed, pickup seed, water, ...
	# X				: X coordinate
	# Y				: Y coordinate
	# Z				: Z coordinate
	# Speed			: Speed setting
	#					FST		: fast movement for moving across a field
	#					WRK		: work speed, used for slow movement like digging, weeding, ...
	# Quantity		: Quantity of water or fertilizer to dose
		
end


class FarmBotDbAccess

	def getNextEvent
	end
	
end
