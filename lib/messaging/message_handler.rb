require 'json'
require 'time'
require_relative 'mesh_message'
require_relative '../command_objects/build_mesh_message'

module FBPi
  # Get the JSON command, received through skynet, and send it to the farmbot
  # command queue Parses JSON messages received through SkyNet.
  class MessageHandler
    class ControllerLoadErrorr < Exception; end
    attr_accessor :message, :bot, :mesh

    def self.add_controller(k)
      self::ROUTES ||= {}
      k = k.to_s
      controller_path = "../controllers/#{k}_controller"
      begin require_relative controller_path; rescue LoadError; nil end
      klass_name = "FBPi::"+k.split('_').map{|w| w.capitalize}.join+"Controller"
      klass = const_get(klass_name)
      ROUTES[k] = klass
    rescue NameError => e
      raise ControllerLoadErrorr, """
      PROBLEM:
        * You failed to load a controller for message type '#{k}'
      SOLUTION:
        * Ensure controller class is named #{klass_name}
        * Save controller as #{controller_path.gsub('..', 'lib')}.rb
        - OR -
        * Ensure #{klass_name} is manually loaded.
       """.squeeze
    end

    [:single_command, :read_status, :exec_sequence,
     :sync_sequence, :unknown,].each {|k| add_controller(k) }

    ## general handling messages
    def initialize(message_hash, bot, mesh)
      @bot, @mesh, @message = bot, mesh, BuildMeshMessage.run!(message_hash)
    end

    def call
      controller = ROUTES[message.type] || UnknownController
      controller.new(message, bot, mesh).call
    rescue => e
      send_error(e)
    end

    # Make a new instance and call() it.
    def self.call(message, bot, mesh)
      self.new(message, bot, mesh).call
    end

    def send_error(error)
      msg = "#{error.message} @ #{error.backtrace.first}"
      bot.log msg
      reply 'error', error: msg
    end

    def reply(type, payl = {})
      raise 'this needs to conform to JSON API!'
      mesh.emit message.from, payl.merge(message_type: type)
    end
  end
end
