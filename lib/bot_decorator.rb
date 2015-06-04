module FBPi
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
      @mesh.data @status_storage.to_h.merge(log: "offline")
      EM.stop
    end
  end
end
