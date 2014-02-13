require 'spec_helper'

describe Device do

  let(:device) do
    Device.new
  end

  describe '#new' do
    it 'initializes a new Device instance' do
      expect(device).to be_kind_of(Device)
    end
  end

  describe '#uuid' do
    it 'returns a valid UUID' do
      expect(device.uuid).to be_kind_of(String)
    end
  end

  describe '#token' do
    it 'returns a valid token' do
      expect(device.token).to be_kind_of(String)
    end
  end
end