require 'json'
require 'time'
require_relative 'mesh_message'

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandler

  attr_accessor :message, :bot, :mesh

  CONTROLLERS = ["single_command", "read_status", "exec_sequence",
                 "sync_sequence", "unknown",]

  # TODO: Namespace FBPi:: for added security. ===============================v
  CONTROLLERS.each {|k| require_relative "../controllers/#{k}_controller"}
  ROUTES = CONTROLLERS.reduce({}) do |accumlator, value|

    klass = const_get(value.split('_').map {|w| w.capitalize}.join+"Controller")
    accumlator[value] = klass
    accumlator
  end # END MAGIC NAMING CONVENTION CODE =====================================^

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

