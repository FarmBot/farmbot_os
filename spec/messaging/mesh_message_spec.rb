require 'spec_helper'

describe MeshMessage do
  let(:msg) do
    MeshMessage.new(from: 'rick',
                    type: 'test',
                    time: '2015-04-15T15:28:56.422Z',
                    payload: {abc: 123})
  end

  it "initializes" do
    expect(msg.from).to eq("rick")
    expect(msg.type).to eq("test")
    expect(msg.time).to be_kind_of(Time)
    expect(msg.payload).to eq(abc: 123)
  end
end
