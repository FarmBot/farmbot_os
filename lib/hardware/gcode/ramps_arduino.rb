## HARDWARE INTERFACE
## ******************

# Communicate with the arduino using a serial interface
# All information is exchanged using a variation of g-code
# Parameters are stored in the database

require 'serialport'

require_relative 'ramps_arduino_values_received.rb'
require_relative 'ramps_arduino_write_status.rb'

class HardwareInterfaceArduino

  attr_accessor :ramps_param, :ramps_main

  # initialize the interface
  #
  def initialize

    @bot_dbaccess = $bot_dbaccess

    @status_debug_msg = $status_debug_msg
    #@status_debug_msg = false
    #@status_debug_msg = true

    # connect to arduino
    connect_board()

    @external_info         = ""

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

      write_status = create_write_status(text, log, onscreen)
      prepare_serial_port(write_status)

      # wait until the arduino responds
      while(write_status.is_finished())

        check_emergency_stop
        process_feedback(write_status)

      end

      log_result_of_execution(write_status)

    rescue Exception => e
      handle_execution_exception(e)
    end
  end

  def create_write_status(text, log, onscreen)
    write_status = HardwareInterfaceArduinoWriteStatus.new
    write_status.text     = text
    write_status.log      = log
    write_status.onscreen = onscreen
    write_status
  end

  def handle_execution_exception(e)
    puts("ST: serial error\n#{e.message}\n#{e.backtrace.inspect}")
    @bot_dbaccess.write_to_log(4,"ST: serial error\n#{e.message}\n#{e.backtrace.inspect}")
    @serial_port.rts = 1
    connect_board
    sleep 5
  end

  def log_result_of_execution(write_status)
 
    # log things if needed
    if write_status.done == 1
      puts 'ST: done' if write_status.onscreen
      @bot_dbaccess.write_to_log(4, 'ST: done') if write_status.log
    else
      puts 'ST: timeout'
      @bot_dbaccess.write_to_log(4, 'ST: timeout')

      sleep 5
    end
  end

  def process_feedback(write_status)

    # check for incoming data
    i = @serial_port.read(1)
    if i != nil
      i.each_char do |c|
   
        add_and_process_characters(write_status, c)

      end
    else
      sleep 0.001
    end
  end

  def add_and_process_characters(write_status, c)

    if c == "\r" or c == "\n"
      if write_status.received.length >= 3

        log_incoming_text(write_status)
        write_status.split_received
        process_code_and_params(write_status)

      end
    else
      write_status.received = write_status.received + c
    end
  end

  def process_code_and_params(write_status)
    # process the feedback
    case write_status.code

      # command received by arduino
      when 'R01'                        
        write_status.timeout = 90

      # command is finished
      when 'R02'
        write_status.done = 1

      # command is finished with errors
      when 'R03'
        write_status.done = 1

      # command is still ongoing
      when 'R04'
        write_status.start = Time.now
        write_status.timeout = 90

      # specific feedback that is processes seperately
      else
        process_value(write_status.code,write_status.params)
    end

    write_status.received = ''

  end

  def prepare_serial_port(write_status)
    puts "WR: #{write_status.text}" if write_status.onscreen
    @bot_dbaccess.write_to_log(4, "WR: #{write_status.text}") if write_status.log
    @serial_port.read_timeout = 2
    @serial_port.write( "#{write_status.text} \n" )    
  end

  def check_emergency_stop    
    # if there is an emergency stop, immediately write it to the arduino
    if ($status.emergency_stop)
     @serial_port.write( "E\n" )
    end
  end

  def log_incoming_text(write_status)
    # some data received
    puts "RD: #{write_status.received}" if write_status.onscreen
    @bot_dbaccess.write_to_log(4,"RD: #{write_status.received}") if write_status.log
  end

  # process values received from arduino
  #
  def process_value(code,text)

    params = HardwareInterfaceArduinoValuesReceived.new

    process_value_split(params, text)

    # depending on the report code, process the values
    # this is done by reading parameter names and their values
    # and respong on it as needed 

    process_value_process_param_list(params,code)
    process_value_process_named_params(params,code)
    process_value_process_text(code,text)

  end

  def process_value_split(params, text)

    # get all separate parameters from the text
    text.split(' ').each do |param|

      par_code  = param[0..0].to_s
      par_value = param[1..-1].to_i

      params.load_parameter(par_code, par_value)

    end
    
  end

  def process_value_process_param_list(params,code)
    if params.p >= 0
      process_value_R21(params,code)
      process_value_R23(params,code)
      process_value_R41(params,code)

    end
  end


  def process_value_R21(params,code)
    # Report parameter value
    if code == 'R21'
      param = @ramps_param.get_param_by_id(params.p)
      if param != nil
        param['value_ar'] = params.v
      end
    end
  end

  def process_value_R23(params,code)
    # Report parameter value and save to database
    if code == 'R23'
      param = @ramps_param.get_param_by_id(params.p)
      if param != nil
        save_param_value(params.p, :by_id, :from_db, params.v)
      end
    end
  end

  def process_value_R41(params,code)
    # Report pin values
    if code == 'R41'
      save_pin_value(params.p, params.v)
    end
  end

  def process_value_process_named_params(params,code)
    process_value_R81(params,code)
    process_value_R82(params,code)
  end

  def process_value_R81(params,code)
    # Report end stops
    if code == 'R81'      
      $status.info_end_stop_x_a = (params.xa == "1")
      $status.info_end_stop_x_b = (params.xb == "1")
      $status.info_end_stop_y_a = (params.ya == "1")
      $status.info_end_stop_y_b = (params.yb == "1")
      $status.info_end_stop_z_a = (params.za == "1")
      $status.info_end_stop_z_b = (params.zb == "1")
    end
  end

  def process_value_R82(params,code)
    # Report position
    if code == 'R82'      

      $status.info_current_x_steps = params.x
      $status.info_current_x       = params.x / @ramps_param.axis_x_steps_per_unit

      $status.info_current_y_steps = params.y
      $status.info_current_y       = params.y / @ramps_param.axis_y_steps_per_unit

      $status.info_current_z_steps = params.z
      $status.info_current_z       = params.z / @ramps_param.axis_z_steps_per_unit

    end
  end

  def process_value_process_text(code,text)
    process_value_process_R83(code,text)
    process_value_process_R99(code,text)
  end  

  def process_value_process_R83(code,text)
    # Report software version
    if code == 'R83'
        $status.device_version = text
    end
  end  

  def process_value_process_R99(code,text)
    # Send a comment
    if code == 'R99'
        puts ">#{text}<"
    end
  end  

  ## additional pin function

  # save a pin measurement
  #
  def save_pin_value(pin_id, pin_val)
    @bot_dbaccess.write_measuements(pin_val, @external_info)
  end

end
