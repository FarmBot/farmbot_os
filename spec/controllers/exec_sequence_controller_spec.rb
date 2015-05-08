require 'spec_helper'

describe ExecSequenceController do
  let(:bot) { FakeBot.new }
  let(:mesh) { FakeMesh.new }
  let(:example_hash) do
    {
      'message_type' => 'exec_sequence',
      'command' => {
        'name' =>'Yowza!',
        'steps' => [
          {'message_type'=>'move_relative', 'command'=> {'x'=>'500'}},
          {'message_type'=>'move_absolute', 'command'=> {'y'=>'1200'}},
          {'message_type' => 'pin_write',
           'command' => {'pin' => 1, 'value' => 1, 'mode' => 0}}
        ]
      }
    }
  end

  let(:message) do
    MeshMessage.new(from: '1234567890',
                    type: 'exec_sequence',
                    payload: example_hash)
  end
  let(:controller) { ExecSequenceController.new(message, bot, mesh) }

  it 'initializes' do
    controller.call
    msg = mesh.last.payload || {}
    raise msg[:error] if msg[:error]
    expect(mesh.last.type).to eq('exec_sequence')
    results = bot.outbound_queue.map(&:to_s)
    ['F41 P1 V1 M0', 'G0 X0 Y1200 Z0', 'G0 X500 Y0 Z0'].each do |gcode|
      expect(results).to include(gcode)
    end
  end

  it 'catches validation errors' do
    message.payload["command"]["steps"] = {}
    ctrl = ExecSequenceController.new(message, bot, mesh)
    ctrl.call
    last_msg = mesh.last.payload
    expect(last_msg[:message_type]).to eq('error')
    expect(last_msg[:error]).to eq("Steps isn't an array")
  end
end
