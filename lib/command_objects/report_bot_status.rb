require 'mutations'

module FBPi
  # This class reads bot status information that has been cached by the Pi. This
  # should not be confused with FetchBotStatus, which actively requests status
  # updates from the bot.
  class ReportBotStatus < Mutations::Command
    required do
      duck :bot, methods: [:status, :commands]
    end

    def execute
      # TODO: Replace everything here with just `bot.status.to_h`. Can't right
      # now because it will be a breaking change to the web app.
      {
        busy: bot.status[:busy],
        current_command: bot.status[:last],
        x: bot.status[:x],
        y: bot.status[:y],
        z: bot.status[:z],
        last_sync: bot.status_storage.fetch(:pi, :last_sync)
      }.merge(pin_info)
       .merge(bot.status.to_h)
       .deep_symbolize_keys
    end

private

    def pin_info
      [*0..13].inject({}) do |hsh, pin|
        hsh["pin#{pin}".to_sym] = bot.status.get_pin(pin)
        hsh
      end
    end
  end
end
