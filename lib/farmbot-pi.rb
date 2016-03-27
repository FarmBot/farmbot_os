require 'farmbot-serial'
require_relative 'messaging/mqtt'
require_relative 'messaging/message_handler'
require_relative 'chores/chore_runner'
require_relative 'models/status_storage.rb'
require_relative 'bot_decorator'
require_relative 'settings'
require_relative 'rest_client'
require 'pry'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => './db/db.sqlite3'
)

class FarmBotPi
  attr_accessor :mqtt, :bot, :handler, :runner, :status_storage
  WEBAPP_URL = FBPi::Settings.webapp_url

  def initialize
    @rest_client    = FBPi::RPiRestClient.new(WEBAPP_URL)
    uuid            = @rest_client.device.current["uuid"]
    token           = @rest_client.config.token
    @mqtt           = MQTTAdapter.new(uuid, token)
    @status_storage = FBPi::StatusStorage.new("db/bot_status.pstore")
    @bot = FBPi::BotDecorator.build(@status_storage, @mqtt, @rest_client)
  end

  def start
    EM.run do
        mqtt.connect { |msg| mqttmessage(msg) }
        FB::ArduinoEventMachine.connect(bot)
        start_chore_runner
        broadcast_status
        # bot.bootstrap
    end
  end

  def mqttmessage(msg)
    FBPi::MessageHandler.call(msg, bot, mqtt)
  end

  def start_chore_runner
    EventMachine::PeriodicTimer.new(FBPi::ChoreRunner::INTERVAL) do
      # TODO: Add chore to check validity of session token / refresh as needed.
      FBPi::ChoreRunner.new(bot).run
    end
  end

  def broadcast_status
    # TODO: Add onconnect() hook instead of timers. Was having issues with
    # socketio client previously (we dont use it anymore).
    EventMachine::Timer.new(4) do
      sync = FBPi::SyncBot.run(bot: bot).result
      mqtt.emit '*', { method: 'sync_sequence', id: nil, params: sync } if sync
      mqtt.emit '*', FBPi::ReportBotStatus.run!(bot: bot)
    end
  end
end
