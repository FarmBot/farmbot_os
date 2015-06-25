require 'spec_helper'

describe FBPi::SingleCommandController do
  let(:bot) do
    bot = FakeBot.new
    bot.commands = FakeOutgoingHandler.new
    bot
  end
  let(:mesh) { FakeMesh.new }
  let(:message) do
    FBPi::MeshMessage.new(from:   '1234567890',
                          method: 'single_command')
  end
  let(:controller) { FBPi::SingleCommandController.new(message, bot, mesh) }

  it 'handles empty message types' do
    expectation = "Unknown message 'NULL'. Most likely, the command "\
      "has not been implemented or does not exist. Try: move relative, move "\
      "absolute, unknown, home x, home y, home z, home all, pin write, "\
      "emergency stop"

    expect { controller.call }.to raise_error(expectation)
  end

  it 'handles parameterless commands' do
    commands = { "home x"         => :home_x,
                 "home y"         => :home_y,
                 "home z"         => :home_z,
                 "home all"       => :home_all,
                 "emergency stop" => :emergency_stop }
    commands.each do |key, val|
      message.method += ".#{key.upcase}"
      controller.call
      expect(bot.commands.last).to eq(val => [])
    end
  end

  it 'moves relative' do
    message.params = {"x"=>10, "y"=>20, "z"=>30, "speed"=>40}
    message.method += ".MOVE RELATIVE"
    controller.call
    expect(bot.commands.log).to include(
      move_relative: [{:x=>10, :y=>20, :z=>30}])
  end

  it 'moves absolute' do
    message.method += ".MOVE ABSOLUTE"
    message.params = {"x"=>10, "y"=>20, "z"=>30, "speed"=>40}
    controller.call
    expect(bot.commands.log).to include(
      move_absolute: [{:x=>10, :y=>20, :z=>30}])
  end

  it 'writes a pin' do
    message.method += ".PIN WRITE"
    message.params = {"pin"=>9, "value1"=>1, "mode"=>0}
    controller.call
    expect(bot.commands.log).to include(
      pin_write: [{:pin=>9, :value=>1, :mode=>0}])
  end
end
