require_relative 'telemetry_message'

module FBPi
  # This class wraps around the FB::Arduino class (farmbot-serial gem) to add
  # extra functionality  that is application specific / not available in
  # farmbot-serial.
  class BotDecorator < SimpleDelegator
    attr_accessor :status_storage, :mesh, :rest_client

    def self.build(status_storage,
                   mesh,
                   rest,
                   arduino_klass = FB::Arduino,
                   serial_obj    = default_serial_object)
      bot = self.new(arduino_klass.new(serial_port: serial_obj))
      bot.status_storage, bot.mesh, bot.rest_client = status_storage, mesh, rest
      bot
    end

    def self.default_serial_object
      begin
        return FB::DefaultSerialPort.new(serial_port)
      rescue TypeError => e
         raise "\n\nSomething went wrong while connecting to the arduino."\
               " Usually, this is a sign that the USB cable is broke or unplugged.\n"
      end
    end

    def self.serial_port
      FBPi::Settings.serial_ports.detect { |f| File.exists?(f) }
    end

    def bootstrap
      ColdStart.run!(bot: self)
    end

    # Called when the socket connection is ready. Go nuts!
    def ready
      log "Online at #{Time.now}"
    end

    def log(message, priority = 'low')
      # Log to screen
      __getobj__.log(message)
      unless message.is_a?(Hash)
        message = {name: 'Log Message', priority: priority, data: message}
      end
      # TODO add X,Y,Z and timestamp to all outbound logs.
      mesh.emit '*', id: nil, result: message
    end

    def emit_changes
      mesh.emit '*', id: nil, result: FBPi::ReportBotStatus.run!(bot: self)
    end

    # This method violates intergalactic law.
    def template_variables
      status
        .to_h
        .merge('time' => Time.now.to_i)
        .reduce({}){ |a, (b, c)| a[b.to_s.downcase] = c; a}
        .tap { |h| h['pins'].map { |k, v| h["pin#{k}"] = v.to_s } }
    end
  end
end
