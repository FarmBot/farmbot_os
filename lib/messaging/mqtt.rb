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

  private

  attr_reader :username, :password

end
