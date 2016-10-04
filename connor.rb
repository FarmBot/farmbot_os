require 'em/mqtt'

input = {
    host: 'localhost',
    username: 'admin@admin.com',
    password: 'password123'
}

EventMachine.run do
  EventMachine::MQTT::ClientConnection.connect(input) do |c|
    c.subscribe('test')
    c.receive_callback do |message|
      p "#{message}"
    end
    EventMachine::PeriodicTimer.new(1.0) do
        puts "-- Publishing time"
        c.publish('test', "The time is #{Time.now}")
    end
    
  end
end