require_relative 'lib/farmbot-pi'

begin
  puts "Connecting..."
  FarmBotPi.new.start
rescue MQTT::NotConnectedException => e
  puts "OH NOES! Farmbot was disconnected from MQTT. Retrying..."
  sleep 1
  retry
end
