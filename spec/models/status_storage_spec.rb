require 'spec_helper'

describe StatusStorage do
  let(:store) do
    store = StatusStorage.new(Tempfile.new('foo').path)
    store.update_attributes(a: 1, b: 2)
    store
  end

  it('loads') { expect(store).to be_kind_of(PStore) }

  it('converts to hash') { expect(store.to_h).to eq(a: 1, b: 2) }

  it 'updates attributes' do
    store.transaction do
      expect(store[:a]).to eq(1)
      expect(store[:b]).to eq(2)
    end
  end

end
