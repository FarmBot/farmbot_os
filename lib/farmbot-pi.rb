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
      mesh.connect
      FB::ArduinoEventMachine.connect(bot)
      start_chore_runner

      mesh.onmessage { |msg| meshmessage(msg) }
      bot.onmessage  { |msg| botmessage(msg) }
      bot.onchange   { |msg| diffmessage(msg) }
      bot.onclose    { EM.stop }
    end
  end

  def botmessage(msg)
    bot.log "BOT MSG: #{msg.name} #{msg.to_s}"
  end

  def meshmessage(msg)
    MessageHandler.call(msg, bot, mesh)
  end

  def start_chore_runner
    EventMachine::PeriodicTimer
      .new(ChoreRunner::INTERVAL) { ChoreRunner.new(bot).run }
  end

  def diffmessage(diff)
    bot.log "BOT DIF: #{diff}" unless diff.keys == [:BUSY]
  end
end
