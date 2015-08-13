require 'mutations'
module FBPi
  # The Arduino does not have persistent storage on board. There are a
  # number of settings that must be set every time the device starts (eg:
  # calibration settings). This object is responsible for bootstrapping bot
  # settings when the device is powered up.
  class ColdStart < Mutations::Command
    required do
      duck :bot, methods: [:emit_changes, :log, :mesh, :onchange, :onclose,
                           :onmessage, :ready, :status, :status_storage]
    end

    def execute
      set_event_handlers
      pull_up_stored_parameters_from_disk
      FetchBotStatus.run!(bot: bot)
      bot
    end

    def set_event_handlers
      bot.onmessage { |msg| botmessage(msg) }
      bot.onchange  { |msg| diffmessage(msg) }
      bot.onclose   { |msg| close(msg) }
      # Why `bott`? Because of unexpected behavior in socket-io-client-simple.
      bott = bot; bot.mesh.socket.on(:ready) { bott.ready }
    end

    def pull_up_stored_parameters_from_disk
      hash = bot.status_storage.to_h(:bot)
      bot.status.transaction do |s|
        hash.each { |k,v| bot.commands.write_parameter(k, v) if is_param? }
      end
    end

    # TODO: This logic ought to live in farmbot-serial.
    def is_param?(key)
      FB::Gcode::PARAMETER_DICTIONARY.invert.keys.include?(key)
    end

    def botmessage(msg)
      bot.log("#{msg.name} #{msg.to_s}") if msg.name != :idle
    end

    def diffmessage(diff)
      bot.status_storage.update_attributes(:bot, diff)
      # Broadcasting busy status changes result in too much network 'noise'.
      bot.emit_changes unless (diff.keys == [:BUSY])
      bot.log "BOT DIF: #{diff}"
    end

    def close
      # Offload all persistent variables to file on shutdown.
      [:bot, :pi].each do |namespace|
        bot.status_storage.update_attributes(namespace, bot.status.to_h)
      end
      bot.log "Bot offline at #{Time.now}", "high"
      EM.stop
    end
  end
end
