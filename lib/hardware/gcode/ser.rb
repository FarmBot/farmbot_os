    #simplest ruby program to read from arduino serial,
    #using the SerialPort gem
    #(http://rubygems.org/gems/serialport)
     
    require "serialport"
     
    #params for serial port
    #port_str = "/dev/ttyUSB0"  #may be different for you
	port_str = "COM4"  #may be different for you
    baud_rate = 9600
    data_bits = 8
    stop_bits = 1
    parity = SerialPort::NONE
    #sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
	
	parameters = 
		{
			"baud" => 9600,
			"data_bits" => 8,
			"stop_bits" => 1,
			"parity" => SerialPort::NONE,	
			"flow_control" => SerialPort::SOFT
		}
	
	comm_port = "COM4"
	sp = SerialPort.new(comm_port, parameters)
		
	i = 0
	
	#while true do
	while i < 10
		i+=1
		#text = 'T' + i.to_s + "\n"
		n = Time.now
		#text = Time.now.to_s.gsub(':','.') + "\n"
		text = Time.now.strftime("%m/%d %H.%M.%S")
		text += "\n"
		sp.write( text )
		#puts( text )
		sleep(1)
    end

	
    #just read forever
    #while true do
    #   while (i = sp.gets.chomp) do       # see note 2
    #      puts i
    #      #puts i.class #String
    #    end
    #end
     
    sp.close                       #see note 1


