require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

  ## logs

  it "write to log" do
    log_text = rand(9999999).to_s
    @db.disable_log_to_screen()
    @db.write_to_log(99,log_text)

    logs = Log.where("module_id = ? AND text = ?", 99 , log_text )

    expect(logs.count).to eq(1)
  end

  it "read_logs_all" do
    log_text = rand(9999999).to_s
    return_list = @db.read_logs_all

    logs = Log.all

    expect(logs.count).to eq(return_list.count)
  end

  it "retrieve_logs" do
    log_text = rand(9999999).to_s
    @db.disable_log_to_screen()
    10.times do 
      @db.write_to_log(99,log_text)
    end

    logs = @db.retrieve_log(99, 10)

    expect(logs.count).to eq(10)
  end

end
