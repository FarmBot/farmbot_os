require 'mutations'
require_relative 'send_message'

module FBPi
  class ReadPin < Mutations::Command
    required do
      integer :pin, min: 0, max: 13 # Probably wrong?
      duck :bot, methods: [:commands]
    end

    def execute
      msg = "Pin #{pin} is #{bot.status.pin(pin).to_s}"
      SendMessage.run!(message: msg, bot: bot)
    end
  end
end
