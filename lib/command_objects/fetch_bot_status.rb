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
      {
        busy: bot.status[:busy],
        current_command: bot.status[:last],
        x: bot.status[:x],
        y: bot.status[:y],
        z: bot.status[:z]
      }.merge(pin_info).deep_symbolize_keys
    end

private

    def pin_info
      # Performs lazy evaluation of pin status. If the pin status is 'unknown',
      # performs a lookup for next status poll. Otherwise, uses cached value.
      [*0..13].inject({}) do |hsh, pin|
        hsh["pin#{pin}".to_sym] = read(pin)
        hsh
      end
    end

    def read(pin)
      val = bot.status.pin(pin)
      (val == :unknown) ? bot.commands.read_parameter(pin) : val
    end
  end
end
