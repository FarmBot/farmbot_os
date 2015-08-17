require 'spec_helper'

describe FBPi::StatusStorage do
  let(:store) do
    store = FBPi::StatusStorage.new(Tempfile.new('foo').path)
    store.update_attributes(:bot, a: 1, b: 2)
    store
  end

  it('loads') { expect(store).to be_kind_of(PStore) }

  it('converts to hash') { expect(store.to_h(:bot)).to eq(a: 1, b: 2) }

  it 'updates attributes' do
    store.transaction do
      expect(store[:bot][:a]).to eq(1)
      expect(store[:bot][:b]).to eq(2)
    end
  end

  it 'disallows access to invalid name spaces' do
    expect do
      store.to_h(:invalid)
    end.to raise_error(FBPi::StatusStorage::InvalidNamespace)
  end
end
