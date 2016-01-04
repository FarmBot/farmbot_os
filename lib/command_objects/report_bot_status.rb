require 'mutations'

module FBPi
  # This class reads bot status information that has been cached by the Pi. This
  # should not be confused with FetchBotStatus, which actively requests status
  # updates from the bot. It will return a Hash that has all relevant
  # information known about the bot
  class ReportBotStatus < Mutations::Command
    required do
      duck :bot, methods: [:status, :commands]
    end

    def execute
      # TODO: Replace everything here with just `bot.status.to_h`. Can't right
      # now because it will be a breaking change to the web app.
      {}
        .merge(status_info)
        .merge(pin_info)
        .merge(other_info)
        .deep_symbolize_keys
    end

private

    def other_info
      bot
        .status
        .to_h
        .except(:X, :Y, :Z, :BUSY, :LAST, :PINS, :S)
    end

    def status_info
      { busy:            bot.status[:busy],
        current_command: bot.status[:last],
        x:               bot.status[:x],
        y:               bot.status[:y],
        z:               bot.status[:z],
        s:               bot.status[:s],
        last_sync:       bot.status_storage.fetch(:pi, :last_sync) }
    end

    def pin_info
      [*0..13].inject({}) do |hsh, pin|
        hsh["pin#{pin}".to_sym] = bot.status.get_pin(pin)
        hsh
      end
    end
  end
end
