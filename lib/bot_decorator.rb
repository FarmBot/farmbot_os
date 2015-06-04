module FBPi
  # This class wraps around the FB::Arduino class to add extra functionality
  # that is application specific / not available in farmbot-serial.
  class BotDecorator < SimpleDelegator
    attr_accessor :status_storage, :mesh

    def self.build(bot, status_storage, mesh)
      bot = self.new(bot)
      bot.status_storage, bot.mesh = status_storage, mesh
      bot
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
      (msg.name == :idle) ? print('.') : log("#{msg.name} #{msg.to_s}")
    end

    def diffmessage(diff)
      @status_storage.update_attributes(diff)
      log "BOT DIF: #{diff}" unless diff.keys == [:BUSY]
    end

    def close(_args)
      @status_storage.update_attributes(status.to_h)
      log "Bot offline at #{Time.now}", "high"
      EM.stop
    end

    def log(message, priority = 'low')
      __getobj__.log(message)
      if message.is_a?(Hash) # TODO 'message' needs its own class.
        m = message.merge(priority: priority)
        m[:name] ||= 'Log Message'
      else
        m = {log: 'Log Message', priority: priority, data: message}
      end
      @mesh.data(m)
    end
  end
end
