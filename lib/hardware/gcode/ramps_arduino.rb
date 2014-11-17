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


    # depending on the report code, process the values
    # this is done by reading parameter names and their values
    # and respong on it as needed 

    case code     

    # Report parameter value
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
        param = @ramps_param.get_param_by_id(ard_par_id)
        if param != nil
          param['value_ar'] = ard_par_val
        end
      end

    # Report parameter value and save to database
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
        param = @ramps_param.get_param_by_id(ard_par_id)
        if param != nil
          save_param_value(ard_par_id, :by_id, :from_db, ard_par_val)
        end
      end

    # Report pin values
    when 'R41'
      pin_id  = -1
      pin_val = 0

      text.split(' ').each do |param|

        par_code  = param[0..0].to_s
        par_value = param[1..-1].to_i

        case par_code
        when 'P'
          pin_id  = par_value
        when 'V'
          pin_val = par_value
        end
      end

      if pin_id >= 0
        save_pin_value(pin_id, pin_val)
      end

    # Report end stops
    when 'R81'
      text.split(' ').each do |param|

        par_code  = param[0..1].to_s
        par_value = param[2..-1].to_s
        end_stop_active = (par_value == "1")

        case par_code
        when 'XA'
          $status.info_end_stop_x_a = end_stop_active
        when 'XB'
          $status.info_end_stop_x_b = end_stop_active
        when 'YA'
          $status.info_end_stop_y_a = end_stop_active
        when 'YB'
          $status.info_end_stop_y_b = end_stop_active
        when 'ZA'
          $status.info_end_stop_z_a = end_stop_active
        when 'ZB'
          $status.info_end_stop_z_b = end_stop_active
        end
      end

    # Report position
    when 'R82'      
      text.split(' ').each do |param|

        par_code  = param[0..0].to_s
        par_value = param[1..-1].to_i

        case par_code
        when 'X'
          $status.info_current_x_steps = par_value
          $status.info_current_x       = par_value / @ramps_param.axis_x_steps_per_unit
        when 'Y'
          $status.info_current_y_steps = par_value
          $status.info_current_y       = par_value / @ramps_param.axis_y_steps_per_unit
        when 'Z'
          $status.info_current_z_steps = par_value
          $status.info_current_z       = par_value / @ramps_param.axis_z_steps_per_unit
        end      
      end

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
