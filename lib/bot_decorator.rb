require_relative 'telemetry_message'

module FBPi
  # This class wraps around the FB::Arduino class to add extra functionality
  # that is application specific / not available in farmbot-serial.
  class BotDecorator < SimpleDelegator
    attr_accessor :status_storage, :mesh, :rest_client

    def self.build(status_storage, mesh, rest, klass = FB::Arduino)
      bot = new_bot!(klass)
      bot.status_storage, bot.mesh, bot.rest_client = status_storage, mesh, rest
      bot
    end

    def self.new_bot!(klass)
      self.new(klass.new(serial_port: FB::DefaultSerialPort.new(serial_port)))
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
      mesh.emit '*', FBPi::FetchBotStatus.run!(bot: self)
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
