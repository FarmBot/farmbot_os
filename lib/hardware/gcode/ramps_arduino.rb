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
  attr_accessor :test_serial_read, :test_serial_write
  attr_accessor :external_info

  # initialize the interface
  #
  def initialize(test_mode)

    @bot_dbaccess = $bot_dbaccess

    @status_debug_msg = $status_debug_msg

    @test_mode         = test_mode
    @test_serial_read  = ""
    @test_serial_write = ""

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
    @serial_port = SerialPort.new(comm_port, parameters) if @test_mode == false

  end

  # write a command to the robot
  #
  def execute_command(text, log, onscreen)

    begin  

      write_status = create_write_status(text, log, onscreen)
      prepare_serial_port(write_status)

      # wait until the arduino responds
      while(write_status.is_busy())

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
    if @test_mode == false
      puts("ST: serial error\n#{e.message}\n#{e.backtrace.inspect}")
    end
    @bot_dbaccess.write_to_log(4,"ST: serial error\n#{e.message}\n#{e.backtrace.inspect}")
    if @test_mode == false
      @serial_port.rts = 1
      connect_board
      sleep 5
    end
  end

  def log_result_of_execution(write_status)
 
    # log things if needed
    if write_status.done == 1
      puts 'ST: done' if write_status.onscreen and @test_mode == false
      @bot_dbaccess.write_to_log(4, 'ST: done') if write_status.log
    else
      puts 'ST: timeout' if @test_mode == false
      @bot_dbaccess.write_to_log(4, 'ST: timeout')

      sleep 5 if @test_mode == false
    end
  end

  # receive all characters coming from the serial port
  #
  def process_feedback(write_status)

    if @test_mode == false
      i = @serial_port.read(1)
    else
      i = @test_serial_read[0]
      @test_serial_read = @test_serial_read[1..-1]
    end

    if i != nil
      i.each_char do |c|

        add_and_process_characters(write_status, c)

      end
    else
      sleep 0.001
    end
  end

  # keep incoming characters in a buffer until it is a complete string
  #
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

  # handle the incoming message depending on the first code number
  #
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

      # specific feedback that is processes separately
      else
        process_value(write_status.code,write_status.params)
    end

    write_status.received = ''

  end

  # set the serial port ready to send
  #
  def prepare_serial_port(write_status)
    puts "WR: #{write_status.text}" if write_status.onscreen
    @bot_dbaccess.write_to_log(4, "WR: #{write_status.text}") if write_status.log
    @serial_port.read_timeout = 2 if @test_mode == false
    clean_serial_buffer() if @test_mode == false
    serial_port_write( "#{write_status.text}\n" )
  end

  # empty the input buffer so no old data is processed
  #
  def clean_serial_buffer
    if @test_mode == false
      while (@serial_port.read(1) != nil)
      end
    else
      @test_serial_read = ''
    end
  end

  # write something to the serial port
  def serial_port_write(text)
    if @test_mode == false
      @serial_port.write( text )
    else
      @test_serial_write = text
    end
  end

  # if there is an emergency stop, immediately write it to the arduino
  #
  def check_emergency_stop    
    if ($status.emergency_stop)
     serial_port_write( "E\n" )
    end
  end

  # write to log
  #
  def log_incoming_text(write_status)
    puts "RD: #{write_status.received}" if write_status.onscreen
    @bot_dbaccess.write_to_log(4,"RD: #{write_status.received}") if write_status.log
  end

  # process values received from arduino
  #
  def process_value(code,text)

    params = HardwareInterfaceArduinoValuesReceived.new

    process_value_split(code, params, text)

    # depending on the report code, process the values
    # this is done by reading parameter names and their values
    # and respong on it as needed 

    process_value_process_param_list(params,code)
    process_value_process_named_params(params,code)
    process_value_process_text(code,text)

  end

  def process_value_split(code, params, text)

    # get all separate parameters from the text
    text.split(' ').each do |param|

      if code == "R81"
       # this is the only code that uses two letter parameters
        par_code  = param[0..1].to_s
        par_value = param[2..-1].to_i
      else
        par_code  = param[0..0].to_s
        par_value = param[1..-1].to_i
      end

      params.load_parameter(par_code, par_value)

    end
    
  end

  def process_value_process_param_list(params,code)
    if params.p != 0
      process_value_R21(params,code)
      process_value_R23(params,code)
      process_value_R41(params,code)
    end
  end


  # Process report parameter value
  #
  def process_value_R21(params,code)
    if code == 'R21'
      param = @ramps_param.get_param_by_id(params.p)
      if param != nil
        param['value_ar'] = params.v
      end
    end
  end

  # Process report parameter value and save to database
  # 
  def process_value_R23(params,code)
    if code == 'R23'
      param = @ramps_param.get_param_by_id(params.p)
      if param != nil
        @ramps_param.save_param_value(params.p, :by_id, :from_db, params.v)
      end
    end
  end

  # Process report pin values
  #
  def process_value_R41(params,code)
    if code == 'R41'
      save_pin_value(params.p, params.v)
    end
  end

  def process_value_process_named_params(params,code)
    process_value_R81(params,code)
    process_value_R82(params,code)
  end

  # Process report end stops
  #
  def process_value_R81(params,code)
    if code == 'R81'      
      $status.info_end_stop_x_a = (params.xa == 1)
      $status.info_end_stop_x_b = (params.xb == 1)
      $status.info_end_stop_y_a = (params.ya == 1)
      $status.info_end_stop_y_b = (params.yb == 1)
      $status.info_end_stop_z_a = (params.za == 1)
      $status.info_end_stop_z_b = (params.zb == 1)
    end
  end

  # Process report position
  def process_value_R82(params,code)
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

  # Process report software version
  #
  def process_value_process_R83(code,text)
    if code == 'R83'
        $status.device_version = text
    end
  end  

  # Process report of a debug comment
  #
  def process_value_process_R99(code,text)
    if code == 'R99'
        puts ">#{text}<" if @test_mode == false
    end
  end  

  ## additional pin function

  # save a pin measurement
  #
  def save_pin_value(pin_id, pin_val)
    @bot_dbaccess.write_measurements(pin_val, @external_info)
  end

end
