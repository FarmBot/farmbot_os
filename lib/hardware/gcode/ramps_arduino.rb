## HARDWARE INTERFACE
## ******************

# Communicate with the arduino using a serial interface
# All information is exchanged using a variation of g-code
# Parameters are stored in the database

require 'serialport'

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

      # write the command to the arduino
      puts "WR: #{text}" if onscreen
      @bot_dbaccess.write_to_log(4, "WR: #{text}") if log
      @serial_port.read_timeout = 2
      @serial_port.write( "#{text} \n" )    

      done     = 0
      r        = ''
      received = ''
      start    = Time.now
      timeout  = 5

      # wait until the arduino responds
      while(Time.now - start < timeout and done == 0)

        # if there is an emergency stop, immediately write it to the arduino
        if ($status.emergency_stop)
          @serial_port.write( "E\n" )
        end

        # check for incoming data
        i = @serial_port.read(1)
        if i != nil
          i.each_char do |c|
            if c == "\r" or c == "\n"
              if r.length >= 3

                # some data received
                puts "RD: #{r}" if onscreen
                @bot_dbaccess.write_to_log(4,"RD: #{r}") if log

                # get the parameter and data part
                c = r[0..2].upcase
                t = r[3..-1].to_s.upcase.strip

                # process the feedback
                case c

                  # command received by arduino
                  when 'R01'                        
                    timeout = 90

                  # command is finished
                  when 'R02'
                    done = 1

                  # command is finished with errors
                  when 'R03'
                    done = 1

                  # command is still ongoing
                  when 'R04'
                    start = Time.now
                    timeout = 90

                  # specific feedback that is processes seperately
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

      # log things if needed
      if done == 1
        puts 'ST: done' if onscreen
        @bot_dbaccess.write_to_log(4, 'ST: done') if log
      else
        puts 'ST: timeout'
        @bot_dbaccess.write_to_log(4, 'ST: timeout')

        sleep 5
      end

    rescue Exception => e
        puts("ST: serial error\n#{e.message}\n#{e.backtrace.inspect}")
        @bot_dbaccess.write_to_log(4,"ST: serial error\n#{e.message}\n#{e.backtrace.inspect}")

        @serial_port.rts = 1
        connect_board

        sleep 5
    end

  end

  # process values received from arduino
  #
  def process_value(code,text)

    p  = -1
    v  = 0
    x  = 0
    y  = 0
    z  = 0
    xa = 0
    xb = 0
    ya = 0
    yb = 0
    za = 0
    zb = 0


    # get all separate parameters from the text
    text.split(' ').each do |param|

      par_code  = param[0..0].to_s
      par_value = param[1..-1].to_i

        case par_code
        when 'P'
          p = par_value
        when 'V'
          v = par_value
        when 'XA'
          xa = par_value
        when 'XB'
          xb = par_value
        when 'YA'
          ya = par_value
        when 'YB'
          yb = par_value
        when 'ZA'
          za = par_value
        when 'ZB'
          zb = par_value
        when 'X'
          x = par_value
        when 'Y'
          y = par_value
        when 'Z'
          z = par_value
        end

    end


    # depending on the report code, process the values
    # this is done by reading parameter names and their values
    # and respong on it as needed 

    if p >= 0

      case code     

        # Report parameter value
        when 'R21'

          param = @ramps_param.get_param_by_id(p)
          if param != nil
            param['value_ar'] = v
          end

        # Report parameter value and save to database
        when 'R23'

          param = @ramps_param.get_param_by_id(p)
          if param != nil
            save_param_value(p, :by_id, :from_db, v)
          end

        # Report pin values
        when 'R41'
          save_pin_value(p, v)

      end
    end

    case code

      # Report end stops
      when 'R81'
        $status.info_end_stop_x_a = (xa == "1")
        $status.info_end_stop_x_b = (xb == "1")
        $status.info_end_stop_y_a = (ya == "1")
        $status.info_end_stop_y_b = (yb == "1")
        $status.info_end_stop_z_a = (za == "1")
        $status.info_end_stop_z_b = (zb == "1")

      # Report position
      when 'R82'      

        $status.info_current_x_steps = x
        $status.info_current_x       = x / @ramps_param.axis_x_steps_per_unit

        $status.info_current_y_steps = y
        $status.info_current_y       = y / @ramps_param.axis_y_steps_per_unit

        $status.info_current_z_steps = z
        $status.info_current_z       = z / @ramps_param.axis_z_steps_per_unit

      # Report software version
      when 'R83'
        $status.device_version = text

      # Send a comment
      when 'R99'
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
