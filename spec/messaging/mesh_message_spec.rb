require 'spec_helper'

describe FBPi::MeshMessage do
  let(:msg) do
    FBPi::MeshMessage.new(from:   'rick',
                          method: 'test',
                          params: {abc: 123})
  end

  it "initializes" do
    expect(msg.from).to eq("rick")
    expect(msg.method).to eq("test")
    expect(msg.params).to eq(abc: 123)
  end
end
