require 'mutations'
require_relative 'send_message'

module FBPi
  # Typically used in the performance of a single step within a sequence whose
  # message_type == "read_pin". This method only reads the value of pins that
  # were REPORTED to the Pi over the serial line. If the pin value has not yet
  # been reported by the arduino, the value will be :unknown
  class ReadPin < Mutations::Command
    required do
      integer :pin, min: 0, max: 13
      duck :bot, methods: [:commands]
    end

    def execute
      SendMessage.run!(message: "Pin #{pin} is #{bot.status.get_pin(pin).to_s}",
                       bot:     bot)
    end
  end
end
