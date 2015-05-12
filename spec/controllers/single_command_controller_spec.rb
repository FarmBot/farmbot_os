require 'spec_helper'

describe SingleCommandController do
  let(:bot) do
    bot = FakeBot.new
    bot.commands = FakeOutgoingHandler.new
    bot
  end
  let(:mesh) { FakeMesh.new }
  let(:message) do
    MeshMessage.new(from:    '1234567890',
                    type:    'single_command',
                    payload: {})
  end
  let(:controller) { SingleCommandController.new(message, bot, mesh) }

  it 'handles empty message types' do
    expectation = "Unknown message 'NULL'. Most likely, the command "\
      "has not been implemented or does not exist. Try: move relative, move "\
      "absolute, unknown, home x, home y, home z, home all, pin write, "\
      "emergency stop"
    expect { controller.call }
      .to raise_error(expectation)
  end

  it 'handles parameterless commands' do
    commands = { "home x"         => :home_x,
                 "home y"         => :home_y,
                 "home z"         => :home_z,
                 "home all"       => :home_all,
                 "emergency stop" => :emergency_stop }
    # => #<MeshMessage:0x000000030c1220
    #  @from="7e3a8a10-6bf6-11e4-9ead-634ea865603d",
    #  @payload={"command"=>{"action"=>"MOVE RELATIVE", "x"=>1000, "y"=>0, "z"=>0, "speed"=>100}},
    #  @type="single_command">
    commands.each do |key, val|
      message.payload = {"command" => {"action" => key}}
      controller.call
      expect(bot.commands.last).to eq(val => [])
    end
  end
end
