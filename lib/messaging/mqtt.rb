# bott = bot; bot.mesh.socket.on(:ready) { bott.ready }
# mesh.connect
# mesh.data(self) unless fetch(:data, '').starts_with?("Nothing")
# mesh.emit '*', FBPi::ReportBotStatus.run!(bot: bot)
# mesh.emit original_message.from, output
# mesh.onmessage { |msg| meshmessage(msg) }
# mesh.socket.on(:error) { |e| puts e.backtrace }
# mesh.toggle_debug!
require 'em/mqtt'

class MQTTAdapter
  def initialize(username,
                 password,
                 host = FBPi::Settings.mqtt_url,
                 port = FBPi::Settings.mqtt_port)
    @username, @password, @host, @port = username, password, host, port
  end

  def connect
    @client = EventMachine::MQTT::ClientConnection.connect(host:     'localhost',
                                                           port:     1883,
                                                           username: 'test123@test.com',
                                                           password: 'password123')
    @client.subscribe("bot/#{@username}/request")
    @client.receive_callback { |m| p(m) }
  end

  def data(*stuff)
    puts "called data()"
  end

  def emit(channel, payload)
    @client.publish("bot/#{username}/response", payload.to_s)
  end

  def onmessage(&blk)
    puts "called onmessage()"
  end

  def onready(&blk)
    puts "called onready()"
  end

  def onerror(&blk)
    puts "called onerror()"
  end

  def toggle_debug!(*wow)
    puts "called toggle_debug()"
  end

private

  attr_reader :username, :password

end
