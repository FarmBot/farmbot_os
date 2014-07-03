require 'serialport'

class HardwareInterface

  # initialize the interface
  #
  def initialize

    load_config()
    connect_board()

    @axis_x_pos = 0
    @axis_y_pos = 0
    @axis_z_pos = 0

  end

  # connect to the serial port and start communicating with the arduino/firmata protocol
  #
  def connect_board

    puts 'connecting to board'

    parameters = 
    {
      "baud"         => 115200,
      "data_bits"    => 8,
      "stop_bits"    => 1,
      "parity"       => SerialPort::NONE,	
      "flow_control" => SerialPort::SOFT
    }

    comm_port = '/dev/ttyACM0'
    @serial_port = SerialPort.new(comm_port, parameters)

  end

  # load the settings for the hardware
  # these are the timeouts and distance settings mainly
  def load_config

    puts 'loading config'

    @axis_x_move_home_timeout   = 15 # seconds after which home command is aborted
    @axis_y_move_home_timeout   = 15
    @axis_z_move_home_timeout   = 150

    @axis_x_invert_axis = false
    @axis_y_invert_axis = false
    @axis_z_invert_axis = false

    @axis_x_steps_per_unit = 5 # steps per milimeter for example
    @axis_y_steps_per_unit = 4
    @axis_z_steps_per_unit = 157

    @axis_x_max = 220
    @axis_y_max = 128
    @axis_z_max = 0

    @axis_x_min = 0
    @axis_y_min = 0
    @axis_z_min = -70
 
    @axis_x_reverse_home = false
    @axis_y_reverse_home = false
    @axis_z_reverse_home = true

    @pump_w_seconds_per_unit = 0.6 # seconds per mililiter

    @max_speed = 200 # steps per second
  end

  # write a command to the robot
  #
  def execute_command( text )
    puts "WR: #{text}"
    @serial_port.write( "#{text} \n" )    

    start = Time.now
    while(Time.now - start < 5)
      while(i = @serial_port.gets) do
        puts i
        #puts i.class
      end
    end
  end

  # move all axis home
  #
  def move_home_all
    execute_command('G28')
  end

  # move the bot to the home position
  #
  def move_home_x
    execute_command('G28')
  end

  # move the bot to the home position
  #
  def move_home_y
    execute_command('G28')
  end

  # move the bot to the home position
  #
  def move_home_z
    execute_command('G28')
  end

  def set_speed( speed )

  end

  # move the bot to the give coordinates
  #
  def move_absolute( coord_x, coord_y, coord_z)

    puts '**move absolute **'

    # calculate the number of steps for the motors to do

    #steps_x = (coord_x - @axis_x_pos) * @axis_x_steps_per_unit
    #steps_y = (coord_y - @axis_y_pos) * @axis_y_steps_per_unit
    #steps_z = (coord_z - @axis_z_pos) * @axis_z_steps_per_unit

    steps_x = coord_x * @axis_x_steps_per_unit
    steps_y = coord_y * @axis_y_steps_per_unit
    steps_z = coord_z * @axis_z_steps_per_unit

    @axis_x_pos = steps_x
    @axis_y_pos = steps_y
    @axis_z_pos = steps_z

    puts "x steps #{steps_x}"
    puts "y steps #{steps_y}"
    puts "z steps #{steps_z}"

    move_to_coord(steps_x, steps_y, steps_z )

  end

  # move the bot a number of units starting from the current position
  #
  def move_relative( amount_x, amount_y, amount_z)

    puts '**move relative **'

    puts "x amount #{amount_x}"
    puts "y amount #{amount_y}"
    puts "z amount #{amount_z}"

    puts "x pos #{@axis_x_pos}"
    puts "y pos #{@axis_y_pos}"
    puts "z pos #{@axis_z_pos}"

    # calculate the number of steps for the motors to do

    #steps_x = (coord_x - @axis_x_pos) * @axis_x_steps_per_unit
    #steps_y = (coord_y - @axis_y_pos) * @axis_y_steps_per_unit
    #steps_z = (coord_z - @axis_z_pos) * @axis_z_steps_per_unit

    steps_x = amount_x * @axis_x_steps_per_unit + @axis_x_pos
    steps_y = amount_y * @axis_y_steps_per_unit + @axis_y_pos
    steps_z = amount_z * @axis_z_steps_per_unit + @axis_z_pos

    @axis_x_pos = steps_x
    @axis_y_pos = steps_y
    @axis_z_pos = steps_z

    puts "x steps #{steps_x}"
    puts "y steps #{steps_y}"
    puts "z steps #{steps_z}"

    puts "x pos #{@axis_x_pos}"
    puts "y pos #{@axis_y_pos}"
    puts "z pos #{@axis_z_pos}"

    move_to_coord( steps_x, steps_y, steps_z )

  end

  # drive the motors so the bot is moved a number of steps
  #
  def move_steps(steps_x, steps_y, steps_z)

    # send the g-code to move to the robot
    execute_command("G00 X#{steps_x} Y#{steps_y} Z#{steps_z} S#{@max_speed}")

  end

  # drive the motors so the bot is moved to a set location
  #
  def move_to_coord(steps_x, steps_y, steps_z)

    # send the g-code to move to the robot
    execute_command("G00 X#{steps_x} Y#{steps_y} Z#{steps_z} S#{@max_speed}")

  end

  def dose_water(amount)
    write_serial("F01 Q#{amount}")
  end

end
