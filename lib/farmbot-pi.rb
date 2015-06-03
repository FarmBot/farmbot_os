require 'farmbot-serial'
require 'meshruby'
require_relative 'messaging/credentials'
require_relative 'messaging/message_handler'
require_relative 'chores/chore_runner'
require_relative 'models/status_storage.rb'
require 'pry'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => './db/db.sqlite3'
)

class FarmBotPi
  attr_accessor :mesh, :bot, :credentials, :handler, :runner, :status_storage

  def initialize(bot: select_correct_bot)
    @credentials = Credentials.new
    @mesh        = EM::MeshRuby.new(@credentials.uuid, @credentials.token, 'ws://mesh.farmbot.it')
    @bot         = bot
    @status_storage = StatusStorage.new("robot_status_registers.pstore")
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
      load_previous_state
      mesh.toggle_debug!
      mesh.connect
      FB::ArduinoEventMachine.connect(bot)
      start_chore_runner
      broadcast_status
      mesh.onmessage { |msg| meshmessage(msg) }
      bot.onmessage  { |msg| botmessage(msg) }
      bot.onchange   { |msg| diffmessage(msg) }
      bot.onclose    { |msg| close(msg) }
      this = self # Binding of caller makes me sad :(
      mesh.socket.on(:ready) do
        this.mesh.data(this.status_storage.to_h.merge(log: "online"))
      end
    end
  end

  def load_previous_state
    previous_states = status_storage.to_h
    bot.status.transaction do |status|
      previous_states.each { |k,v| status[k] = v }
    end
  end

  def botmessage(msg)
    if msg.name == :idle
      print '.'
    else
      bot.log "BOT MSG: #{msg.name} #{msg.to_s}"
    end
  end

  def meshmessage(msg)
    MessageHandler.call(msg, bot, mesh)
  end

  def start_chore_runner
    EventMachine::PeriodicTimer.new(ChoreRunner::INTERVAL) do
      ChoreRunner.new(bot).run
    end
  end

  def broadcast_status
    EventMachine::PeriodicTimer.new(0.4) do
      null_msg = MeshMessage.new(from: '*', type: 'read_status', payload: {})
      ReadStatusController.new(null_msg, bot, mesh).call
    end
  end

  def diffmessage(diff)
    @status_storage.update_attributes(diff)
    bot.log "BOT DIF: #{diff}" unless diff.keys == [:BUSY]
  end

  def close(_args)
    @status_storage.update_attributes(bot.status.to_h)
    @mesh.data @status_storage.to_h.merge(log: "offline")
    EM.stop
  end
end
