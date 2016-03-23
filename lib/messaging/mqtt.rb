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
    @username = username
    @password = password
    @host = host
    @port = port
  end

  def connect(&blk)
    @client = EventMachine::MQTT::ClientConnection.connect(host:     @host,
                                                           port:     @port,
                                                           username: @username,
                                                           password: @password)
    @client.subscribe("bot/#{@username}/request")
    @client.receive_callback(&blk)
    puts "Connected!"
  end

  def data(payload)
    @client.publish("bot/#{username}/data", payload.to_json)
  end

  def emit(_channel, payload)
    @client.publish("bot/#{username}/response", payload.to_json)
  end

  def onmessage
    puts 'called onmessage()'
  end

  def onready
    puts 'called onready()'
  end

  def onerror
    puts 'called onerror()'
  end

  def toggle_debug!(*_wow)
    puts 'called toggle_debug()'
  end

  private

  attr_reader :username, :password

end
