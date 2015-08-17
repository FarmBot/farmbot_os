require 'mutations'

module FBPi
  # Typically, the pi does not need to poll the Arduino to know its status
  # because updates are broadcast over the serial line when statuses change. The
  # typical exception to this rule is device startup, when there is no data to
  # perform a diff on. When this is the case, you can run FetchBotStatus, which
  # polls the device for all of its status registers. SEE ALSO: ReportBotStatus
  class FetchBotStatus < Mutations::Command
    RELEVANT_PARAMETERS   = [0,1,11,12,13,21,22,23,31,32,33,41,42,43,51,52,53,
                             61,62,63,71,72,73]
    required do
      duck :bot, methods: [:status, :commands]
    end

    def execute
      read_pins
      read_paramters
      bot.status.to_h
    end

private

    def read_pins
      0.upto(13) { |pin| bot.commands.read_pin(pin) }
    end

    def read_paramters
      RELEVANT_PARAMETERS.each { |code| bot.commands.read_parameter(code) }
    end
  end
end
