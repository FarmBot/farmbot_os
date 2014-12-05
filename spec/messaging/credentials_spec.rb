require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

  it "increments param version" do
    param_name = 'PARAM_VERSION'
    @db.write_parameter(param_name, 1)
    @db.increment_parameters_version
    return_val = @db.read_parameter(param_name)

    expect(return_val).to eq(2)
  end
end
