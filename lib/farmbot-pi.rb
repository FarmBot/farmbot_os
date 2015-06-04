require 'farmbot-serial'
require 'meshruby'
require_relative 'messaging/credentials'
require_relative 'messaging/message_handler'
require_relative 'chores/chore_runner'
require_relative 'models/status_storage.rb'
require_relative 'bot_decorator'
require 'pry'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => './db/db.sqlite3'
)

class FarmBotPi
  attr_accessor :mesh, :bot, :credentials, :handler, :runner, :status_storage

  def initialize(bot: select_correct_bot)
    @credentials    = FBPi::Credentials.new
    @mesh           = EM::MeshRuby.new(@credentials.uuid,
                                       @credentials.token,
                                       'ws://mesh.farmbot.it')
    @status_storage = FBPi::StatusStorage.new("bot_status.pstore")
    @bot            = FBPi::BotDecorator.build(bot, @status_storage, @mesh)
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
      FB::ArduinoEventMachine.connect(bot)
      start_chore_runner
      broadcast_status
      mesh.onmessage { |msg| meshmessage(msg) }
      bot.bootstrap
      this = self # Binding of caller makes me sad :(
      mesh.socket.on(:ready) do
        this.mesh.data(this.status_storage.to_h.merge(log: "online"))
      end
    end
  end

  def meshmessage(msg)
    FBPi::MessageHandler.call(msg, bot, mesh)
  end

  def start_chore_runner
    EventMachine::PeriodicTimer.new(FBPi::ChoreRunner::INTERVAL) do
      FBPi::ChoreRunner.new(bot).run
    end
  end

  def broadcast_status
    EventMachine::PeriodicTimer.new(0.4) do
      null_msg = FBPi::MeshMessage.new(from: '*',
                                       type: 'read_status',
                                       payload: {})
      FBPi::ReadStatusController.new(null_msg, bot, mesh).call
    end
  end
end
