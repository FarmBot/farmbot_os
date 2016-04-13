require 'mutations'
require_relative 'fetch_bot_status'
module FBPi
  # The Arduino does not have persistent storage on board. There are a
  # number of settings that must be set every time the device starts (eg:
  # calibration settings). This object is responsible for bootstrapping bot
  # settings when the device is powered up.
  class ColdStart < Mutations::Command
    IGNORE_LIST = [:idle, :received, :done]

    required do
      duck :bot, methods: [:emit_changes, :log, :mesh, :onchange, :onclose,
                           :onmessage, :ready, :status, :status_storage]
    end

    def execute
      pull_up_stored_parameters_from_disk
      FetchBotStatus.run!(bot: bot)
      set_event_handlers
      bot
    end

    def set_event_handlers
      bot.onmessage { |msg| botmessage(msg) }
      bot.onchange  { |msg| diffmessage(msg) }
      bot.onclose   { |msg| close(msg) }
    end

    def pull_up_stored_parameters_from_disk
      hash = bot.status_storage.to_h(:bot)
      teh_codez = FB::Gcode::PARAMETER_DICTIONARY.invert
      bot.status.transaction do |s|
        hash.each { |k,v|
          param_number = teh_codez.fetch(k, k)
          bot.commands.write_parameter(param_number, v) }
      end
    end

    def botmessage(msg)
      # Callbacks here, yo.
    end

    def diffmessage(diff)
      bot.status_storage.update_attributes(:bot, diff)
      if (diff.keys != [:BUSY])
        # Broadcasting busy status changes result in too much network 'noise'.
        # We could broadcast bot's busy status, but why?
        bot.emit_changes
        bot.log diff
      end
    end

    def close()
      # Offload all persistent variables to file on shutdown.
      [:bot, :pi].each do |namespace|
        bot.status_storage.update_attributes(namespace, bot.status.to_h)
      end
      bot.log "Bot offline at #{Time.now}", "high"
      EM.stop
    end
  end
end
