require 'farmbot-serial'
require 'meshruby'
require_relative 'lib/messaging/credentials'
require_relative 'lib/messaging/messagehandler'
require 'pry'
require 'active_record'

class FarmBotPi
  attr_accessor :mesh, :bot, :credentials, :handler

  def initialize(env = :development)
    config = YAML::load(File.open('./db/database.yml'))
    # ActiveRecord::Base.establish_connection(config[env])
    @credentials = Credentials.new
    @mesh        = EM::MeshRuby.new(@credentials.uuid, @credentials.token)
    @bot         = FB::Arduino.new
    @handler     = MessageHandler
  end

  def incoming_message(msg)
    print '.'
    handler.call(msg, bot, mesh)
  end

  def start
    # mesh.toggle_debug!

    EM.run do
      mesh.connect
        mesh.onmessage { |msg| incoming_message(msg) }

      FB::ArduinoEventMachine.connect(bot)
        bot.onmessage { |msg| bot.log "BOT MSG: #{msg}"}
        bot.onchange { |diff| bot.log "BOT DIF: #{diff}"}
        bot.onclose { puts 'Disconnected'; EM.stop }
    end
  end
end

FarmBotPi.new.start

