require 'json'
require 'time'
require_relative 'mesh_message'
Dir["lib/controllers/*.rb"].each { |f| load(f) }

# Get the JSON command, received through skynet, and send it to the farmbot
# command queue Parses JSON messages received through SkyNet.
class MessageHandler

  attr_accessor :message, :bot, :mesh

  ROUTES = {"single_command" => SingleCommandController}

  ## general handling messages
  def initialize(message_hash, bot, mesh)
    @bot, @mesh = bot, mesh
    payl = message_hash.fetch('payload', {})
    @message = MeshMessage.new(from: message_hash['fromUuid'],
                               type: payl['message_type'],
                               time: payl['time_stamp'],
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
    mesh.emit message.from,
              payl.merge(message_type: type,
                         confirm_id: message.time,
                         time_stamp: Time.now.to_f.to_s)
  end
end

