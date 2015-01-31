require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

  ## refreshes

  it "check_refresh initial" do
    @db.check_refresh
    @db.save_refresh()
    return_val = @db.check_refresh
    expect(return_val).to eq(false)
  end

  it "check_refresh after increment" do
    @db.check_refresh
    @db.save_refresh()
    @db.increment_refresh()
    return_val = @db.check_refresh
    expect(return_val).to eq(true)
  end

  it "check_refresh save" do
    @db.check_refresh
    @db.save_refresh()
    return_val = @db.check_refresh
    expect(return_val).to eq(false)
  end

end
