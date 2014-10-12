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
  attr_reader :param_version_db, :param_version_ar, :params_in_sync

  # initialize the interface
  #
  def initialize

    @status_debug_msg = $status_debug_msg
    #@status_debug_msg = false
    #@status_debug_msg = true

    # init database and parameters
    @bot_dbaccess = $bot_dbaccess
    @params = Array.new
    load_param_names()
    load_config_from_database()

    # connect to arduino
    connect_board()

    @bot_dbaccess = $bot_dbaccess

    @axis_x_pos = 0
    @axis_y_pos = 0
    @axis_z_pos = 0

    @axis_x_pos_conv = 0
    @axis_y_pos_conv = 0
    @axis_z_pos_conv = 0

    @axis_x_steps_per_unit = 0
    @axis_y_steps_per_unit = 0
    @axis_z_steps_per_unit = 0

    load_param_values_non_arduino()

    @device_version   = 'unknown'
    @param_version_db = 0
    @param_version_ar = 0
    @params_in_sync   = false

  end

  ## INTERFACE FUNCTIONS
  ## *******************


  # set standard pin value
  #
  def pin_std_set_value(pin, value, mode)
    execute_command("F41 P#{pin} V#{value} M#{mode}", false, @status_debug_msg)
    #execute_command("F41 P#{pin} V#{value}", false, true)
  end

  # read standard pin
  #
  def pin_std_read_value(pin, mode)
    execute_command("F42 P#{pin} M#{mode}", false, @status_debug_msg)
  end

  # set standard pin mode
  #
  def pin_std_set_mode(pin, mode)
    execute_command("F43 P#{pin} M#{mode}", false, @status_debug_msg)
  end

  # set pulse on standard pin
  #
  def pin_std_pulse(pin, value1, value2, time, mode)
    execute_command("F44 P#{pin} V#{value1} W#{value2} T#{time} M#{mode}", false, @status_debug_msg)    
  end

  # check to see of parameters in arduino are up to date
  #
  def check_parameters

    # read the parameter version in the database and in the device 
    read_parameter_from_device(0)
    @params.each do |p|
      if p['id'] == 0
        @param_version_ar = p['value_ar']
      end
    end

    @param_version_db = @bot_dbaccess.read_parameter_with_default('PARAM_VERSION', 0)

    # if the parameters in the device is different from the database parameter version
    # read and compare each parameter and write to device is different
    if @param_version_db != @param_version_ar
      load_param_values_non_arduino()
      differences_found_total = false
      @params.each do |p|
        if p['id'] > 0
          difference = check_and_write_parameter(p)
          if difference then
            @params_in_sync = false
            differences_found_total = true
          end
        end
      end
      if !differences_found_total
        @params_in_sync = true
        write_parameter_to_device(0, @param_version_db)
      else
        @params_in_sync = false
      end
    end
  end

  # synchronise a parameter value
  #
  def check_and_write_parameter(param)

     # read value from device and database
     read_parameter_from_device(param['id'])
     param['value_db'] = @bot_dbaccess.read_parameter_with_default(param['name'], 0)

     differences_found = false

     # if the parameter value between device and database is different, write value to device
     if param['value_db'] != param ['value_ar']
       differences_found = true
       write_parameter_to_device(param['id'],param['value_db'])
     end

    return differences_found

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

  # calibrate x axis
  #
  def calibrate_x
    execute_command('F14', true, false)
  end

  # calibrate y axis
  #
  def calibrate_y
    execute_command('F15', true, false)
  end

  # calibrate z axis
  #
  def calibrate_z
    execute_command('F16', true, false)
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
    execute_command("F21 P#{id}", false, false)
  end

  # write a parameter value to arduino
  #
  def write_parameter_to_device(id, value)
    execute_command("F22 P#{id} V#{value}", false, false)
  end

  ## DATABASE AND SETTINGS HANDLING
  ## ******************************

  # load non-arduino parameters
  #
  def load_param_values_non_arduino

    p = get_param_by_name('MOVEMENT_STEPS_PER_UNIT_X')
    @axis_x_steps_per_unit = p['value_db']

    p = get_param_by_name('MOVEMENT_STEPS_PER_UNIT_Y')
    @axis_y_steps_per_unit = p['value_db']

    p = get_param_by_name('MOVEMENT_STEPS_PER_UNIT_Z')
    @axis_z_steps_per_unit = p['value_db']

  end

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
    param_name_add('MOVEMENT_TIMEOUT_X'           , 11,   15)
    param_name_add('MOVEMENT_TIMEOUT_Y'           , 12,   15)
    param_name_add('MOVEMENT_TIMEOUT_Z'           , 13,   15)
    param_name_add('MOVEMENT_INVERT_ENDPOINTS_X'  , 21,    0)
    param_name_add('MOVEMENT_INVERT_ENDPOINTS_Y'  , 22,    0)
    param_name_add('MOVEMENT_INVERT_ENDPOINTS_Z'  , 23,    0)
    param_name_add('MOVEMENT_INVERT_MOTOR_X'      , 31,    0)
    param_name_add('MOVEMENT_INVERT_MOTOR_Y'      , 32,    0)
    param_name_add('MOVEMENT_INVERT_MOTOR_Z'      , 33,    0)
    param_name_add('MOVEMENT_STEPS_ACC_DEC_X'     , 41,  100)
    param_name_add('MOVEMENT_STEPS_ACC_DEC_Y'     , 42,  100)
    param_name_add('MOVEMENT_STEPS_ACC_DEC_Z'     , 43,  100)
    param_name_add('MOVEMENT_HOME_UP_X'           , 51,    0)
    param_name_add('MOVEMENT_HOME_UP_Y'           , 52,    0)
    param_name_add('MOVEMENT_HOME_UP_Z'           , 53,    0)
    param_name_add('MOVEMENT_MIN_SPD_X'           , 61,  200)
    param_name_add('MOVEMENT_MIN_SPD_Y'           , 62,  200)
    param_name_add('MOVEMENT_MIN_SPD_Z'           , 63,  200)
    param_name_add('MOVEMENT_MAX_SPD_X'           , 71, 1000)
    param_name_add('MOVEMENT_MAX_SPD_Y'           , 72, 1000)
    param_name_add('MOVEMENT_MAX_SPD_Z'           , 73, 1000)
    param_name_add('MOVEMENT_LENGTH_X'            ,801, 1000)
    param_name_add('MOVEMENT_LENGTH_Y'            ,802, 1000)
    param_name_add('MOVEMENT_LENGTH_Z'            ,803, 1000)
    param_name_add('MOVEMENT_STEPS_PER_UNIT_X'    ,901,    5)
    param_name_add('MOVEMENT_STEPS_PER_UNIT_Y'    ,902,    5)
    param_name_add('MOVEMENT_STEPS_PER_UNIT_Z'    ,903,    5)

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

  # get parameter object by name or id
  #
  def get_param(name_or_id, by_name_or_id)
    param = nil
    @params.each do |p|
      if (by_name_or_id == :by_id   and p['id']   == name_or_id)
        param = p
      end
      if (by_name_or_id == :by_name and p['name'] == name_or_id)
        param = p
      end
    end
    return param
  end

  # read parameter value from memory
  #
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

  #def get_param_value_by_name(name)
  #end

  # save parameter value to the database
  #
  def save_param_value(name_or_id, by_name_or_id, from_device_or_db, value)

    param = get_param(name_or_id, by_name_or_id)

    if param != nil and from_device_or_db == :from_device
      param['value_ar'] = value
    end
    if param != nil and from_device_or_db == :from_db
      param['value_db'] = value
    end

    @bot_dbaccess.write_parameter(param['name'],value)
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
                  when 'R04'
                    start = Time.now
                    timeout = 90
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
         sleep 0.001
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
          param['value_ar'] = ard_par_val
        end
      end

    when 'R23'
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
          save_param_value(ard_par_id, :by_id, :from_db, ard_par_val)
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
