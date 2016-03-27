require 'spec_helper'

describe FBPi::ExecSequenceController do
  let(:bot) { FakeBot.new }
  let(:mesh) { FakeMesh.new }
  let(:example_hash) do
    {
      'message_type' => 'exec_sequence',
      'name' =>'Yowza!',
      '_id'  => "ABC123-THIS-IS-MY-UUID",
      'steps' => [
          {'message_type'=>'move_relative',
           'position' => 0,
           'command'=> {'x'=>'500'}},

          {'message_type'=>'move_absolute',
           'position' => 1,
           'command'=> {'y'=>'1200'}},

          {'message_type' => 'pin_write',
           'position' => 2,
           'command' => {'pin' => 1, 'value' => 1, 'mode' => 0}}
        ]
    }
  end

  let(:message) do
    FBPi::MeshMessage.new(id: '1234567890',
                          method: 'exec_sequence',
                          params: example_hash)
  end
  let(:controller) { FBPi::ExecSequenceController.new(message, bot, mesh) }

  it 'initializes' do
    controller.call
    expect(mesh.last.method).to eq('exec_sequence')
    results = bot.outbound_queue.map(&:to_s)
    ['F41 P1 V1 M0', 'G0 X0 Y1200 Z0', 'G0 X500 Y0 Z0'].each do |gcode|
      expect(results).to include(gcode)
    end
  end

  it 'catches validation errors' do
    message.params["steps"] = {}
    ctrl = FBPi::ExecSequenceController.new(message, bot, mesh)
    ctrl.call
    last_msg = mesh.last.params
    expect(last_msg[:error]).to_not be_nil
    expect(last_msg[:error][:error]).to include("Steps isn't an array")
  end
end
