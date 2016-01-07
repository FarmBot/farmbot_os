require 'mutations'

module FBPi
  # This class reads bot status information that has been cached by the Pi. This
  # should not be confused with FetchBotStatus, which actively requests status
  # updates from the bot. This command will return a Hash that has all relevant
  # information known about the bot. It's like a serializer, sort of.
  class ReportBotStatus < Mutations::Command
    required do
      duck :bot, methods: [:status, :commands]
    end

    def execute
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
        .map { |k, v| [k.to_s.downcase, v] }
        .to_h
    end

    def pi_info
      { last_sync:  bot.status_storage.fetch(:pi, :LAST_SYNC),
        ip_address: bot.status_storage.fetch(:pi, :IP_ADDRESS) }
    end

    def pin_info
      [*0..13].inject({}) do |hsh, pin|
        hsh["pin#{pin}".to_sym] = bot.status.get_pin(pin)
        hsh
      end
    end
  end
end
