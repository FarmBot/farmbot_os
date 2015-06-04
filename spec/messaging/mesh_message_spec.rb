require 'spec_helper'

describe FBPi::MeshMessage do
  let(:msg) do
    FBPi::MeshMessage.new(from: 'rick',
                          type: 'test',
                          payload: {abc: 123})
  end

  it "initializes" do
    expect(msg.from).to eq("rick")
    expect(msg.type).to eq("test")
    expect(msg.payload).to eq(abc: 123)
  end
end
