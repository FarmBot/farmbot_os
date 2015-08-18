require_relative 'telemetry_message'

module FBPi
  # This class wraps around the FB::Arduino class to add extra functionality
  # that is application specific / not available in farmbot-serial.
  class BotDecorator < SimpleDelegator
    attr_accessor :status_storage, :mesh, :rest_client

    def self.build(status_storage,
                   mesh,
                   rest,
                   arduino_klass = FB::Arduino,
                   serial_obj    = FB::DefaultSerialPort.new(serial_port))
      bot = self.new(arduino_klass.new(serial_port: serial_obj))
      bot.status_storage, bot.mesh, bot.rest_client = status_storage, mesh, rest
      bot
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
        message = {log: 'Log Message', priority: priority, data: message}
      end
      TelemetryMessage.build(status.to_h.merge(message)).publish(@mesh)
    end

    def emit_changes
      mesh.emit '*', method: 'read_status',
                     params: FBPi::ReportBotStatus.run!(bot: self),
                     id:     nil
    end

    # This method seems to be violating some sort of intergalactic law. I don't
    # like the idea of the decorator holding on to logic related to rendering of
    # liquid templates (http://liquidmarkup.org/).
    def template_variables
      status
        .to_h
        .merge('time' => Time.now)
        .reduce({}){ |a, (b, c)| a[b.to_s.downcase] = c; a}
        .tap { |h| h['pins'].map { |k, v| h["pin#{k}"] = v.to_s } }
    end
  end
end
