require 'json'
require 'time'
require_relative 'mesh_message'
require_relative '../command_objects/build_mesh_message'
require_relative '../command_objects/dispose_trash_message'
require_relative '../command_objects/resolve_controller'

module FBPi
  # Every time a message comes in from MeshBlu, a new MessageHandler is created.
  # Take a bot, message hash and MeshBlu connection and routes it to a specific
  # controller.
  class MessageHandler
    attr_accessor :message, :bot, :mesh

    ## general handling messages
    def initialize(mqtt_message, bot, mesh)
      @bot, @mesh = bot, mesh
      @message = BuildMeshMessage.run!(message: mqtt_message)
    rescue Mutations::ValidationException => e
      puts "BOT WAS UNABLE TO PARSE MALFORMED MESSAGE! DANGER IMMINENT!"
      @message = DisposeTrashMessage.run!(mqtt_message)
    end

    def call
      controller_klass = ResolveController.run!(method: message.method)
      controller_klass.new(message, bot, mesh).call
    rescue Exception => e
      send_error(e)
    end

    # Make a new instance and call() it.
    def self.call(message, bot, mesh)
      self.new(message, bot, mesh).call
    end

    def send_error(error)
      msg = "#{error.message} @ #{error.backtrace.first}"
      bot.log msg
      reply 'error', message: error.message, backtrace: error.backtrace
    end

    def reply(method, reslt = {})
      SendMeshResponse.run!(original_message: message,
                            mesh:             mesh,
                            method:           method,
                            result:           reslt)
    end

  end
end
