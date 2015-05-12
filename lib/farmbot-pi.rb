require 'farmbot-serial'
require 'meshruby'
require_relative 'messaging/credentials'
require_relative 'messaging/message_handler'
require_relative 'chore_runner/chore_runner'
require 'pry'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => './db/db.sqlite3'
)

class FarmBotPi
  attr_accessor :mesh, :bot, :credentials, :handler, :runner

  def initialize(bot: select_correct_bot)
    @credentials = Credentials.new
    @mesh        = EM::MeshRuby.new(@credentials.uuid, @credentials.token)
    @bot         = bot
  end

  def select_correct_bot
    if File.file?('serial_port.txt')
      com = File.read('serial_port.txt').strip
    else
      com = '/dev/ttyACM0'
    end
    serial_port = FB::DefaultSerialPort.new(com)
    FB::Arduino.new(serial_port: serial_port)
  end

  def start
    EM.run do
      mesh.toggle_debug!
      mesh.connect
      mesh.onmessage { |msg|
        bot.log msg unless msg.fetch("payload", {})['message_type'] == 'read_status'
        MessageHandler.call(msg, bot, mesh) }

      FB::ArduinoEventMachine.connect(bot)

      bot.onmessage do |msg|
        # unless [:received, :done, :report_parameter_value,
        #         :idle].include?(msg.name)
          bot.log "BOT MSG: #{msg.name} #{msg.to_s}"
        # end
      end

      EventMachine::PeriodicTimer
        .new(ChoreRunner::INTERVAL) { ChoreRunner.new(bot).run }

      bot.onchange do |diff|
        bot.log "BOT DIF: #{diff}" unless diff.keys == [:BUSY]
      end

      bot.onclose { EM.stop }
    end
  end
end
