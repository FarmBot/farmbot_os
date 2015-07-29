require 'mutations'

module FBPi
  # This class fetches bot status information as it becomes available, as a hash
  # If it is unknown, it asks the device to report it (and you will need to
  # query the data again until the bot reports back with the information). This
  # is particularly useful for emiting telemetry data every few seconds.
  class FetchBotStatus < Mutations::Command
    required do
      duck :bot, methods: [:status, :commands]
    end

    def execute
      status_hash
    end

private

    def status_hash
      {
        busy: bot.status[:busy],
        current_command: bot.status[:last],
        x: bot.status[:x],
        y: bot.status[:y],
        z: bot.status[:z],
        last_sync: bot.status_storage.fetch(:bot, :last_sync)
      }.merge(pin_info).deep_symbolize_keys
    end

    def pin_info
      [*0..13].inject({}) do |hsh, pin|
        hsh["pin#{pin}".to_sym] = read(pin)
        hsh
      end
    end

    def read(pin)
      val = bot.status.pin(pin)
      # If the pin status is 'unknown', performs lookup for next status poll.
      bot.commands.read_parameter(pin) if val == :unknown
      val
    end
  end
end
