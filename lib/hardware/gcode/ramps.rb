## HARDWARE INTERFACE
## ******************

# Communicate with the arduino using a serial interface
# All information is exchanged using a variation of g-code
# Parameters are stored in the database

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

    @params = Array.new
    load_param_names()
    load_config_from_database()

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

  ## INTERFACE FUNCTIONS
  ## *******************

  # check to see of parameters in arduino are up to date
  #
  def check_parameters

    read_parameter_from_device(0)

    param = 

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
    execute_command("G00 X#{steps_x} Y#{steps_y} Z#{steps_z}")
  end

  # drive the motors so the bot is moved to a set location
  #
  def move_to_coord(steps_x, steps_y, steps_z)
    execute_command("G00 X#{steps_x} Y#{steps_y} Z#{steps_z}", true, false)
  end

  # dose an amount of water (in ml)
  #
  def dose_water(amount)
    write_serial("F01 Q#{amount}")
  end

  # read a parameter from arduino
  #
  def read_parameter_from_device(id)
    execute_command("G21 P#{id}", true, false)
  end

  # write a parameter value to arduino
  #
  def write_parameter_to_device(id, value)
    execute_command("G22 P#{id} V#{value}", true, false)
  end

  ## DATABASE AND SETTINGS HANDLING
  ## ******************************

  # load the settings for the hardware
  # these are the timeouts and distance settings mainly
  #
  def load_config_from_database
    @params.each do |p|
       p['value_db'] = @bot_dbaccess.read_parameter_with_default(p['name'], p['default'])
    end
  end

  # load the id's of the arduino parameters
  #
  def load_param_names
    param_name_add('PARAM_VERSION'                ,  0,    0)
    param_name_add('MOVEMENT_TIMEOUT_X'           ,  1,   15)
    param_name_add('MOVEMENT_TIMEOUT_Y'           ,  2,   15)
    param_name_add('MOVEMENT_TIMEOUT_Z'           ,  3,   15)
    param_name_add('MOVEMENT_INVERT_ENDPOINTS_X'  ,  4,    0)
    param_name_add('MOVEMENT_INVERT_ENDPOINTS_Y'  ,  5,    0)
    param_name_add('MOVEMENT_INVERT_ENDPOINTS_Z'  ,  6,    0)
    param_name_add('MOVEMENT_INVERT_MOTOR_X'      ,  7,    0)
    param_name_add('MOVEMENT_INVERT_MOTOR_Y'      ,  8,    0)
    param_name_add('MOVEMENT_INVERT_MOTOR_Z'      ,  9,    0)
    param_name_add('MOVEMENT_STEPS_ACC_DEC_X'     , 10,  100)
    param_name_add('MOVEMENT_STEPS_ACC_DEC_Y'     , 11,  100)
    param_name_add('MOVEMENT_STEPS_ACC_DEC_Z'     , 12,  100)
    param_name_add('MOVEMENT_HOME_UP_X'           , 13,    0)
    param_name_add('MOVEMENT_HOME_UP_Y'           , 14,    0)
    param_name_add('MOVEMENT_HOME_UP_Z'           , 15,    0)
    param_name_add('MOVEMENT_MIN_SPD_X'           , 16,  200)
    param_name_add('MOVEMENT_MIN_SPD_Y'           , 17,  200)
    param_name_add('MOVEMENT_MIN_SPD_Z'           , 18,  200)
    param_name_add('MOVEMENT_MAX_SPD_X'           , 19, 1000)
    param_name_add('MOVEMENT_MAX_SPD_Y'           , 20, 1000)
    param_name_add('MOVEMENT_MAX_SPD_Z'           , 21, 1000)
  end

  # add a parameter to the param list
  #
  def param_name_add(name, id, default)
    param = Hash.new
    param['name']     = name
    param['id']       = id
    param['value_db'] = 0
    param['value_ar'] = 0
    param['default']  = default
    @params << param
  end

  # get the parameter object by name
  #
  def get_param_by_name(name) 
    param = nil
    @params.each do |p|
      if p['name'] == name
        param = p
      end
    end
    return param
  end

  # get the parameter object by id
  #
  def get_param_by_id(id)
    param = nil
    @params.each do |p|
      if p['id'] == id
        param = p
      end
    end
    return param
  end

  def get_param(name_or_id, by_name_or_id)
    param = nil
    @params.each do |p|
      if (by_name_or_id == :by_id   and p['id']   == id)
        param = p
      end
      if (by_name_or_id == :by_name and p['name'] == name)
        param = p
      end
    end
    return param
  end

  def get_param_value_by_id(name_or_id, by_name_or_id, from_device_or_db, default_value)
    value = default_value
    
    param = get_param(id, by_name_or_id)
    if param != nil and from_device_or_db == :from_device
      value =  param['value_ar']
    end
    if param != nil and from_device_or_db == :from_db
      value =  param['value_db']
    end

  end

  def get_param_value_by_name(name)
  end

  ## ARDUINO HANLDING
  ## ****************

  # connect to the serial port and start communicating with the arduino/firmata protocol
  #
  def connect_board

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

  # write a command to the robot
  #
  def execute_command( text , log, onscreen)

    begin

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

        sleep 5
      end

    rescue Exception => e
        puts("ST: serial error\n#{e.message}\n#{e.backtrace.inspect}")
        @bot_dbaccess.write_to_log(1,"ST: serial error\n#{e.message}\n#{e.backtrace.inspect}")

        @serial_port.rts = 1
        connect_board

        sleep 5
    end

  end

  # process values received from arduino
  #
  def process_value(code,text)
    case code     
    when 'R21'
      ard_par_id  = -1
      ard_par_val = 0

      text.split(' ').each do |param|

        par_code  = param[0..0].to_s
        par_value = param[1..-1].to_i

        case par_code
        when 'P'
          ard_par_id  = par_value
        when 'V'
          ard_par_val = par_value
        end
      end

      if ard_par_id >= 0
        param = get_param_by_id(ard_par_id)
        if param != nil
          param[value_db] = ard_par_val
        end
      end

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

end
