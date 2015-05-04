require 'json'
require 'time'
require_relative 'mesh_message'

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
    klass_name = k.split('_').map{|w| w.capitalize}.join+"Controller"
    klass = const_get(klass_name)
    ROUTES[k] = klass
  rescue NameError
    raise ControllerLoadErrorr, """
    PROBLEM:
      * You failed to load a controller for message type '#{k}'
    SOLUTION:
      * Ensure controller class is named #{klass_name}
      * Save controller as #{controller_path.gsub('..', 'lib')}.rb
      - OR -
      * Ensure #{klass_name} is manually loaded.
     and""".squeeze
  end

  [:single_command, :read_status, :exec_sequence,
   :sync_sequence, :unknown,].each {|k| add_controller(k) }

  ## general handling messages
  def initialize(message_hash, bot, mesh)
    @bot, @mesh = bot, mesh
    payl = message_hash.fetch('payload', {})
    @message = MeshMessage.new(from: message_hash['fromUuid'],
                               type: payl['message_type'],
                               payload: payl)
  end

  def call
    controller = ROUTES[message.type] || UnknownController
    controller.new(message, bot, mesh).call
    send_confirmation
  rescue => e
    send_error(e)
  end

  # Make a new instance and call() it.
  def self.call(message, bot, mesh)
    self.new(message, bot, mesh).call
  end

  # send a reply to the back end system
  #
  def send_confirmation
    reply 'confirmation'
  end

  def send_error(error)
    msg = "#{error.message} @ #{error.backtrace.first}"
    bot.log msg
    reply 'error', error: msg
  end

  def reply(type, payl = {})
    mesh.emit message.from, payl.merge(message_type: type)
  end
end

