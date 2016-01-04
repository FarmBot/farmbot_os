require 'mutations'

module FBPi
  # This class reads bot status information that has been cached by the Pi. This
  # should not be confused with FetchBotStatus, which actively requests status
  # updates from the bot. This command will return a Hash that has all relevant
  # information known about the bot
  class ReportBotStatus < Mutations::Command
    required do
      duck :bot, methods: [:status, :commands]
    end

    def execute
      # TODO: Replace everything here with just `bot.status.to_h`. Can't right
      # now because it will be a breaking change to the web app.
      {}
        .merge(bot_info)
        .merge(pin_info)
        .merge(pi_info)
        .deep_symbolize_keys
    end

private

    def bot_info
      bot
        .status
        .to_h
        .except(:PINS)
        .delete_if { |k, v| k.to_s.start_with?("UNKNOWN") }
    end

    def pi_info
      { LAST_SYNC: bot.status_storage.fetch(:pi, :last_sync) }
    end

    def pin_info
      [*0..13].inject({}) do |hsh, pin|
        hsh["PIN#{pin}".to_sym] = bot.status.get_pin(pin)
        hsh
      end
    end
  end
end
