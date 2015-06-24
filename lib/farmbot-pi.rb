require 'farmbot-serial'
require 'meshruby'

require_relative 'messaging/credentials'
require_relative 'messaging/message_handler'
require_relative 'chores/chore_runner'
require_relative 'models/status_storage.rb'
require_relative 'bot_decorator'
require_relative 'settings'
require 'pry'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => './db/db.sqlite3'
)

class FarmBotPi
  attr_accessor :mesh, :bot, :credentials, :handler, :runner, :status_storage
  WEBAPP_URL = FBPi::Settings.webapp_url
  MESH_URL   = FBPi::Settings.meshblu_url

  def initialize(bot: 'delete this param')
    @credentials    = FBPi::Credentials.new
    @mesh           = EM::MeshRuby.new(@credentials.uuid,
                                       @credentials.token,
                                       "ws://#{MESH_URL}")
    @status_storage = FBPi::StatusStorage.new("bot_status.pstore")
    @rest_client   = FbResource::Client.new do |config|
      config.uuid  = credentials.uuid
      config.token = credentials.token
      config.url   = "http://#{WEBAPP_URL}"
    end
    @bot = FBPi::BotDecorator.build(@status_storage, @mesh, @rest_client)
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
      FBPi::SyncBot.run(bot: bot)
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
      mesh.emit '*', FBPi::FetchBotStatus.run!(bot: bot)
    end
  end
end
