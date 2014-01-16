require 'firmata'
#require './FarmBotControlInterface.rb'

class HardwareInterface

	def initialize
		@pos_x = 0.0
		@pos_y = 0.0
		@pos_z = 0.0
		
		# should come from configuration:
		@move_home_timeout   = 3 # seconds after which home command is aborted
		@sleep_after_pin_set = 0.005
		@sleep_after_enable  = 0.001

		@invert_axis_x = false
		@invert_axis_y = false
		@invert_axis_z = false

		@steps_per_unit_x = 10 # steps per milimeter for example
		@steps_per_unit_y = 10
		@steps_per_unit_z = 10
			
		@boardDevice = "/dev/ttyACM0"

		@pin_led = 13

		@pin_stp_x = 54
		@pin_dir_x = 55
		@pin_enb_x = 38

		@pin_stp_y = 60
		@pin_dir_y = 61
		@pin_enb_y = 56

		@pin_stp_z = 46
		@pin_dir_z = 48
		@pin_enb_z = 62

		@pin_min_x = 3
		@pin_max_x = 2

		@pin_min_y = 14
		@pin_max_y = 15

		@pin_min_z = 18
		@pin_max_z = 19
		
		@board = Firmata::Board.new @boardDevice
		@board.connect

		# set motor driver pins to output and set enables for the drivers to off

		@board.set_pin_mode(@pin_enb_x, Firmata::Board::OUTPUT)
		@board.set_pin_mode(@pin_dir_x, Firmata::Board::OUTPUT)
		@board.set_pin_mode(@pin_stp_x, Firmata::Board::OUTPUT)

		@board.set_pin_mode(@pin_enb_y, Firmata::Board::OUTPUT)
		@board.set_pin_mode(@pin_dir_y, Firmata::Board::OUTPUT)
		@board.set_pin_mode(@pin_stp_y, Firmata::Board::OUTPUT)

		@board.set_pin_mode(@pin_enb_z, Firmata::Board::OUTPUT)
		@board.set_pin_mode(@pin_dir_z, Firmata::Board::OUTPUT)
		@board.set_pin_mode(@pin_stp_z, Firmata::Board::OUTPUT)

		@board.digital_write(@pin_enb_x, Firmata::Board::HIGH)
		@board.digital_write(@pin_enb_y, Firmata::Board::HIGH)
		@board.digital_write(@pin_enb_z, Firmata::Board::HIGH)

		# set the end stop pins to input

		@board.set_pin_mode(@pin_min_x, Firmata::Board::INPUT)
		@board.set_pin_mode(@pin_min_y, Firmata::Board::INPUT)
		@board.set_pin_mode(@pin_min_z, Firmata::Board::INPUT)

		@board.set_pin_mode(@pin_max_x, Firmata::Board::INPUT)
		@board.set_pin_mode(@pin_max_y, Firmata::Board::INPUT)
		@board.set_pin_mode(@pin_max_z, Firmata::Board::INPUT)

		@board.toggle_pin_reporting(@pin_min_x)
		@board.toggle_pin_reporting(@pin_min_y)
		@board.toggle_pin_reporting(@pin_min_z)

		@board.toggle_pin_reporting(@pin_max_x)
		@board.toggle_pin_reporting(@pin_max_y)
		@board.toggle_pin_reporting(@pin_max_z)

	end

	# move the bot to the home position

	def moveHomeX
		moveHome(@pin_enb_x, @pin_dir_x, @pin_stp_x, @pin_min_x, @invert_axis_x)
		@pos_x = 0
	end

	def moveHomeY
		moveHome(@pin_enb_y, @pin_dir_y, @pin_stp_y, @pin_min_y, @invert_axis_y)
		@pos_y = 0
	end

	def moveHomeZ
		moveHome(@pin_enb_z, @pin_dir_z, @pin_stp_z, @pin_min_z, @invert_axis_z)
		@pos_z = 0
	end

	def setSpeed( speed )
		
	end

	def moveHome(pin_enb, pin_dir, pin_stp, pin_min, invert_axis)

		# set the direction and enable

		@board.digital_write(pin_enb, Firmata::Board::LOW)
		sleep @sleep_after_enable

		if invert_axis == false
			@board.digital_write(pin_dir, Firmata::Board::LOW)
		else
			@board.digital_write(pin_dir, Firmata::Board::HIGH)
		end
		sleep @sleep_after_pin_set

		start = Time.now
		home  = 0

		# keep setting pulses at the step pin until the end stop is reached of a time is reached

		while home == 0 do		

			@board.read_and_process
			span = Time.now - start
			
			if span > @move_home_timeout
				home = 1
				puts 'move home timed out'
			end

			if @board.pins[pin_min].value == 1
				home = 1
				puts 'end stop reached'
			end

			if home == 0
				@board.digital_write(pin_stp, Firmata::Board::HIGH)
				sleep @sleep_after_pin_set
				@board.digital_write(pin_stp, Firmata::Board::LOW)
				sleep @sleep_after_pin_set		
			end
		end

		# disavle motor driver
		@board.digital_write(pin_dir, Firmata::Board::LOW)

	end


	# move the bot to the give coordinates

	def moveAbsolute( coord_x, coord_y, coord_z)

		puts '**move absolute **'

		# calculate the number of steps for the motors to do

		steps_x = (coord_x - @pos_x) * @steps_per_unit_x
		steps_y = (coord_y - @pos_y) * @steps_per_unit_y
		steps_z = (coord_z - @pos_z) * @steps_per_unit_z

		puts "x steps #{steps_x}"
		puts "y steps #{steps_y}"
		puts "z steps #{steps_z}"

		moveSteps( steps_x, steps_y, steps_z )

	end

	# move the bot a number of units starting from the current position

	def moveRelative( amount_x, amount_y, amount_z)

		puts '**move relative **'

		# calculate the number of steps for the motors to do

		steps_x = amount_x * @steps_per_unit_x
		steps_y = amount_y * @steps_per_unit_y
		steps_z = amount_z * @steps_per_unit_z

		puts "x steps #{steps_x}"
		puts "y steps #{steps_y}"
		puts "z steps #{steps_z}"

		moveSteps( steps_x, steps_y, steps_z )

	end

	def moveSteps( steps_x, steps_y, steps_z)
		
		puts '**move steps **'
		puts "x #{steps_x}"
		puts "y #{steps_y}"
		puts "z #{steps_z}"
		
		# set the direction and the enable bit for the motor drivers

		if (steps_x < 0 and @invert_axis_x == false) or (steps_x > 0 and @invert_axis_x == true)
			@board.digital_write(@pin_enb_x, Firmata::Board::LOW)
			@board.digital_write(@pin_dir_x, Firmata::Board::LOW)
		end
	
		if (steps_x > 0 and @invert_axis_x == false) or (steps_x < 0 and @invert_axis_x == true)
			@board.digital_write(@pin_enb_x, Firmata::Board::LOW)
			@board.digital_write(@pin_dir_x, Firmata::Board::HIGH)
		end

		if (steps_y < 0 and @invert_axis_y == false) or (steps_y > 0 and @invert_axis_y == true)
			@board.digital_write(@pin_enb_y, Firmata::Board::LOW)
			@sleep_after_enable
			@board.digital_write(@pin_dir_y, Firmata::Board::LOW)
			sleep @sleep_after_pin_set
		end
	
		if (steps_y > 0 and @invert_axis_y == false) or (steps_y < 0 and @invert_axis_y == true)
			@board.digital_write(@pin_enb_y, Firmata::Board::LOW)
			@sleep_after_enable
			@board.digital_write(@pin_dir_y, Firmata::Board::HIGH)
			sleep @sleep_after_pin_set
		end

		if (steps_z < 0 and @invert_axis_z == false) or (steps_z > 0 and @invert_axis_z == true)
			@board.digital_write(@pin_enb_z, Firmata::Board::LOW)
			@sleep_after_enable
			@board.digital_write(@pin_dir_z, Firmata::Board::LOW)
			@sleep_after_pin_set
		end
	
		if (steps_z > 0 and @invert_axis_z == false) or (steps_z < 0 and @invert_axis_z == true)
			@board.digital_write(@pin_enb_z, Firmata::Board::LOW)
			@board.digital_write(@pin_dir_z, Firmata::Board::HIGH)
			@sleep_after_pin_set
		end

		# make the steps positive numbers 

		nr_steps_x = steps_x.abs
		nr_steps_y = steps_y.abs
		nr_steps_z = steps_z.abs

		# loop until all steps are done

		while nr_steps_x > 0 or nr_steps_y > 0 or nr_steps_z > 0 do

			# read all input pins and check the end stops

			@board.read_and_process

			#puts "x min = #{@board.pins[@pin_min_x].value} | x max = #{@board.pins[@pin_max_x].value} "
			#puts "y min = #{@board.pins[@pin_min_y].value} | y max = #{@board.pins[@pin_max_y].value} "
			#puts "z min = #{@board.pins[@pin_min_z].value} | z max = #{@board.pins[@pin_max_z].value} "

			if @board.pins[@pin_min_x].value == 1
				nr_steps_x = 0
				@pos_x = 0
				puts 'end stop min x'
			end

			if @board.pins[@pin_max_x].value == 1
				nr_steps_x = 0
				puts 'end stop max x'
			end

			if @board.pins[@pin_min_y].value == 1
				nr_steps_y = 0
				@pos_y = 0
				puts 'end stop min y'
			end

			if @board.pins[@pin_max_y].value == 1
				nr_steps_y = 0
				puts 'end stop max y'
			end

			if @board.pins[@pin_min_z].value == 1
				nr_steps_z = 0
				@pos_z = 0
				puts 'end stop min z'
			end

			if @board.pins[@pin_max_z].value == 1
				nr_steps_z = 0
				puts 'end stop max z'
			end

			# send the step pulses to the motor drivers

			if nr_steps_x > 0
				@board.digital_write(@pin_stp_x, Firmata::Board::HIGH)
				sleep @sleep_after_pin_set
				@board.digital_write(@pin_stp_x, Firmata::Board::LOW)
				sleep @sleep_after_pin_set
				@pos_x += 1 / @steps_per_unit_x
				nr_steps_x -= 1
			end

			if nr_steps_y > 0
				@board.digital_write(@pin_stp_y, Firmata::Board::HIGH)
				sleep @sleep_after_pin_set
				@board.digital_write(@pin_stp_y, Firmata::Board::LOW)
				sleep @sleep_after_pin_set
				@pos_y += 1 / @steps_per_unit_y
				nr_steps_y -= 1
	
			end
		
			if nr_steps_z > 0
				@board.digital_write(@pin_stp_z, Firmata::Board::HIGH)
				sleep @sleep_after_pin_set
				@board.digital_write(@pin_stp_z, Firmata::Board::LOW)
				sleep @sleep_after_pin_set
				@pos_z += 1 / @steps_per_unit_z
				nr_steps_z -= 1
			end

		end

		# disable motor drivers

		@board.digital_write(@pin_enb_x, Firmata::Board::HIGH)
		@board.digital_write(@pin_enb_y, Firmata::Board::HIGH)
		@board.digital_write(@pin_enb_z, Firmata::Board::HIGH)
			
		#while (X - pos_X).abs < 1/steps_per_unit_X

		puts '*move done*'
					
	end	
end
