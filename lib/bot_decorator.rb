require_relative 'telemetry_message'

module FBPi
  # This class wraps around the FB::Arduino class to add extra functionality
  # that is application specific / not available in farmbot-serial.
  class BotDecorator < SimpleDelegator
    attr_accessor :status_storage, :mesh, :rest_client

    def self.build(_, status_storage, mesh, rest)
      bot = new_bot!
      bot.status_storage, bot.mesh, bot.rest_client = status_storage, mesh, rest
      bot
    end

    def self.new_bot!
      ard = FB::Arduino.new(serial_port: FB::DefaultSerialPort.new(serial_port))
      self.new(ard)
    end

    def self.serial_port
      FBPi::Settings.serial_ports.detect { |f| File.exists?(f) }
    end

    def bootstrap
      load_previous_state
      onmessage { |msg| botmessage(msg) }
      onchange  { |msg| diffmessage(msg) }
      onclose   { |msg| close(msg) }
      this = self; mesh.socket.on(:ready) { this.ready }
    end

    def ready
       log "Online at #{Time.now}"
    end

    def load_previous_state
      status.transaction do |s| status_storage.to_h.each { |k,v| s[k] = v } end
    end

    def botmessage(msg)
      log("#{msg.name} #{msg.to_s}") if msg.name != :idle
    end

    def diffmessage(diff)
      @status_storage.update_attributes(diff)
      log "BOT DIF: #{diff}" unless diff.keys == [:BUSY]
    end

    def close(*)
      @status_storage.update_attributes(status.to_h)
      log "Bot offline at #{Time.now}", "high"
      EM.stop
    end

    def log(message, priority = 'low')
      # Log to screen
      __getobj__.log(message)
      TelemetryMessage.build(message).publish(@mesh)
    end
  end
end
