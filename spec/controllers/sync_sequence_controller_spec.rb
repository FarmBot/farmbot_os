require 'spec_helper'

describe SyncSequenceController do
  let(:bot) { FakeBot.new }
  let(:mesh) { FakeMesh.new }
  let(:message) do
    MeshMessage.new from: '1234567890',
                    type: 'sync_sequence',
                    payload:{"command"=>
                            [{"_id"=>"553f8aa270726f4090000000",
                              "start_time"=>"2015-04-28T23:00:00.000Z",
                              "end_time"=>"2015-04-30T23:00:00.000Z",
                              "repeat"=>4,
                              "time_unit"=>"hourly",
                              "sequence"=>
                                { "name"=>"FARMBOT II: A New Hope",
                                  "steps"=>
                                    [{ "message_type" => "move_relative",
                                        "command" => {"x"=>"1100"} } ] } } ] }
  end
  let(:controller) { SyncSequenceController.new(message, bot, mesh) }

  it "initializes" do
    controller.call
    msg = mesh.last.payload || {}
    raise msg[:error] if msg[:error]
    expect(mesh.last.type).to eq("sync_sequence")
  end
end
