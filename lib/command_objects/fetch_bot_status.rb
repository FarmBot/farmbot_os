require 'mutations'

module FBPi
  # Typically, the pi does not need to poll the Arduino to know its status
  # because updates are broadcast over the serial line when statuses change. The
  # exception to this rule is device startup, when there is no data to perform a
  # diff on. When this is the case, you can run FetchBotStatus, which polls the
  # device for all of its status registers. This command sends as many as 22
  # requests down the serial line in one action, so hopefully it can be
  # refactored later on. SEE ALSO: ReportBotStatus
  class FetchBotStatus < Mutations::Command
    RELEVANT_PARAMETERS   = [0,1,11,12,13,21,22,23,31,32,33,41,42,43,51,52,53,
                             61,62,63,71,72,73]
    required do
      duck :bot, methods: [:status, :commands]
    end

    def execute
      read_pins
      read_parameters
      read_network_info
      FBPi::ReportBotStatus.run!(bot: bot)
    end

    def read_network_info
      network_info = {}
      # Usually, begin..rescue nil end is sloppy. In this case, it doesnt matter
      # It's not important enough to crash the program over. It's a convenience.
      begin network_info[:IP_ADDRESS] = `curl http://ipecho.net/plain`[0...39]
      rescue nil
      end
      bot.status_storage.update_attributes(:pi, network_info)
    end

    def read_pins
      0.upto(13) { |pin| bot.commands.read_pin(pin) }
    end

    def read_parameters
      RELEVANT_PARAMETERS.each { |code| bot.commands.read_parameter(code) }
    end
  end
end
