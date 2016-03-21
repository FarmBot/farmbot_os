# bott = bot; bot.mesh.socket.on(:ready) { bott.ready }
# mesh.connect
# mesh.data(self) unless fetch(:data, '').starts_with?("Nothing")
# mesh.emit '*', FBPi::ReportBotStatus.run!(bot: bot)
# mesh.emit '*', method: 'read_status',
# mesh.emit '*', { method: 'sync_sequence', id: nil, params: sync } if sync
# mesh.emit original_message.from, output
# mesh.onmessage { |msg| meshmessage(msg) }
# mesh.socket.on(:error) { |e| puts e.backtrace }
# mesh.toggle_debug!
require 'em/mqtt'

class MQTTAdapter
  def initialize(username, password)
  client = EventMachine::MQTT::ClientConnection.connect({
    host: 'localhost',
    username: 'test123@test.com',
    password: 'password123'
  });
  # c.subscribe('mqtt/demo')
  # c.receive_callback do |message|
  #   p message
  # end
  end

  def data
  end

  def connect
  end

  def emit(channel, payload)
  end

  def onmessage(&blk)
  end

  def onready(&blk)
  end

  def onerror(&blk)
  end

  def toggle_debug!(*wow)
  end
end
