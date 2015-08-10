require 'mutations'

module FBPi
  class ReportBotStatus < Mutations::Command
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
        hsh["pin#{pin}".to_sym] = bot.status.get(pin)
        hsh
      end
    end
  end
end
