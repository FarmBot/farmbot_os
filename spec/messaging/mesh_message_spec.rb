require 'spec_helper'

describe FBPi::MeshMessage do
  let(:msg) do
    FBPi::MeshMessage.new(id:   '1r2i3c4k5',
                          method: 'test',
                          params: {abc: 123})
  end

  it "initializes" do
    expect(msg.id).to eq("1r2i3c4k5")
    expect(msg.method).to eq("test")
    expect(msg.params).to eq(abc: 123)
  end
end
