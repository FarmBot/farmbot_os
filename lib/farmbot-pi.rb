require 'farmbot-serial'
require 'meshruby'
require_relative 'messaging/credentials'
require_relative 'messaging/message_handler'
require 'pry'

class FarmBotPi
  attr_accessor :mesh, :bot, :credentials, :handler

  def initialize(env = :development)
    @credentials = Credentials.new
    @mesh        = EM::MeshRuby.new(@credentials.uuid, @credentials.token)
    @bot         = FB::Arduino.new
  end

  def start
    EM.run do
      mesh.connect
      mesh.onmessage { |msg| MessageHandler.call(msg, bot, mesh) }

      FB::ArduinoEventMachine.connect(bot)

      bot.onmessage do |msg|
        unless [
          :received, :done, :report_parameter_value, :idle].include?(msg.name)
          bot.log "BOT MSG: #{msg.name} #{msg.to_s}"
        end
      end

      bot.onchange do |diff|
        bot.log "BOT DIF: #{diff}" unless diff.keys == [:BUSY]
      end

      bot.onclose { EM.stop }
    end
  end
end
