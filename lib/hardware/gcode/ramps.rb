require 'serialport'

class HardwareInterface

  attr_reader :axis_x_pos, :axis_x_pos_conv, :axis_x_end_stop_a, :axis_x_end_stop_b
  attr_reader :axis_y_pos, :axis_y_pos_conv, :axis_y_end_stop_a, :axis_y_end_stop_b
  attr_reader :axis_z_pos, :axis_z_pos_conv, :axis_z_end_stop_a, :axis_z_end_stop_b
  attr_reader :device_version

  # initialize the interface
  #
  def initialize

    @status_debug_msg = false

    load_config()
    connect_board()

    @bot_dbaccess = $bot_dbaccess

    @axis_x_pos = 0
    @axis_y_pos = 0
    @axis_z_pos = 0

    @axis_x_pos_conv = 0
    @axis_y_pos_conv = 0
    @axis_z_pos_conv = 0

    @device_version = 'unknown'
  end

  # connect to the serial port and start communicating with the arduino/firmata protocol
  #
  def connect_board

    #puts 'connecting to board'

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
  #
  def load_config

    #puts 'loading config'

    @axis_x_move_home_timeout   = 15 # seconds after which home command is aborted
    @axis_y_move_home_timeout   = 15
    @axis_z_move_home_timeout   = 150

    @axis_x_invert_axis = false
    @axis_y_invert_axis = false
    @axis_z_invert_axis = false

    @axis_x_steps_per_unit = 5 # steps per milimeter for example
    @axis_y_steps_per_unit = 5
    @axis_z_steps_per_unit = 150

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
  def execute_command( text , log, onscreen)

    puts "WR: #{text}" if onscreen
    @bot_dbaccess.write_to_log(1, "WR: #{text}") if log

    @serial_port.read_timeout = 2
    #@serial_port.write_timeout = 2
    @serial_port.write( "#{text} \n" )    

    done     = 0
    r        = ''
    received = ''
    start    = Time.now
    timeout  = 5

    while(Time.now - start < timeout and done == 0)
      i = @serial_port.read(1)
      if i != nil
        i.each_char do |c|
          if c == "\r" or c == "\n"
            if r.length >= 3
              puts "RD: #{r}" if onscreen
              @bot_dbaccess.write_to_log(1,"RD: #{r}") if log
              c = r[0..2].upcase
              t = r[3..-1].to_s.upcase.strip
              case c
                when 'R01'
                  timeout = 90
                when 'R02'
                  done = 1
                when 'R03'
                  done = 1
                else
                  process_value(c,t)
              end
              r = ''
            end
          else
            r = r + c
          end
        end
      else
       sleep 0.05
      end
    end

    if done == 1
      puts 'ST: done' if onscreen
      @bot_dbaccess.write_to_log(1, 'ST: done') if log
    else
      puts 'ST: timeout'
      @bot_dbaccess.write_to_log(1, 'ST: timeout')
      #@serial_port.break 1
      @serial_port.rts = 1
      #connect_board
      sleep 10
    end
  end


  # process values received from arduino
  #
  def process_value(code,text)
    case code     
    when 'R81'
      text.split(' ').each do |param|

        par_code  = param[0..1].to_s
        par_value = param[2..-1].to_s
        end_stop_active = (par_value == "1")

        case par_code
        when 'XA'
          @axis_x_end_stop_a = end_stop_active              
        when 'XB'
          @axis_x_end_stop_b = end_stop_active              
        when 'YA'
          @axis_y_end_stop_a = end_stop_active              
        when 'YB'
          @axis_y_end_stop_b = end_stop_active              
        when 'ZA'
          @axis_z_end_stop_a = end_stop_active              
        when 'ZB'
          @axis_z_end_stop_b = end_stop_active              
        end      
      end
    when 'R82'      
      text.split(' ').each do |param|

        par_code  = param[0..0].to_s
        par_value = param[1..-1].to_i

        case par_code
        when 'X'
          @axis_x_pos      = par_value
          @axis_x_pos_conv = par_value / @axis_x_steps_per_unit
        when 'Y'
          @axis_y_pos       = par_value
          @axis_y_pos_conv = par_value / @axis_y_steps_per_unit
        when 'Z'
          @axis_z_pos      = par_value
          @axis_z_pos_conv = par_value / @axis_z_steps_per_unit
        end      
      end
    when 'R83'
      @device_version = text
    when 'R99'
      puts ">#{text}<"
    end
  end

  # read end stop status from the device
  #
  def read_end_stops()
    execute_command('F81', false, @status_debug_msg)
  end

  # read current coordinates from the device
  #
  def read_postition()
    execute_command('F82', false, @status_debug_msg)
  end
  # read current software version
  #
  def read_device_version()
    execute_command('F83', false, @status_debug_msg)
  end

  # move all axis home
  #
  def move_home_all
    execute_command('G28', true, false)
  end

  # move the bot to the home position
  #
  def move_home_x
    execute_command('F11', true, false)
  end

  # move the bot to the home position
  #
  def move_home_y
    execute_command('F12', true, false)
  end

  # move the bot to the home position
  #
  def move_home_z
    execute_command('F13', true, false)
  end

  def set_speed( speed )

  end

  # move the bot to the give coordinates
  #
  def move_absolute( coord_x, coord_y, coord_z)

    # calculate the number of steps for the motors to do

    steps_x = coord_x * @axis_x_steps_per_unit
    steps_y = coord_y * @axis_y_steps_per_unit
    steps_z = coord_z * @axis_z_steps_per_unit

    @axis_x_pos = steps_x
    @axis_y_pos = steps_y
    @axis_z_pos = steps_z

    move_to_coord(steps_x, steps_y, steps_z )

  end

  # move the bot a number of units starting from the current position
  #
  def move_relative( amount_x, amount_y, amount_z)

    # calculate the number of steps for the motors to do

    steps_x = amount_x * @axis_x_steps_per_unit + @axis_x_pos
    steps_y = amount_y * @axis_y_steps_per_unit + @axis_y_pos
    steps_z = amount_z * @axis_z_steps_per_unit + @axis_z_pos

    @axis_x_pos = steps_x
    @axis_y_pos = steps_y
    @axis_z_pos = steps_z

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
    execute_command("G00 X#{steps_x} Y#{steps_y} Z#{steps_z}", false, false)

  end

  def dose_water(amount)
    write_serial("F01 Q#{amount}")
  end

end
