require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync        = Mutex.new
    @db                   = DbAccess.new('development')
    #@db.max_nr_log_lines  = 10
  end

  ## logs

  it "write to log" do
    log_text = rand(9999999).to_s
    @db.disable_log_to_screen()
    @db.write_to_log(99,log_text)

    logs = Log.where("module_id = ? AND text = ?", 99 , log_text )

    expect(logs.count).to eq(1)
  end

  it "write to log and clean log" do

    @db.disable_log_to_screen()

    # write 15 lines

    # fill up the logging db if not filled to capacity

    while Log.count < @db.max_nr_log_lines
      log_text = rand(9999999).to_s
      @db.write_to_log(99,log_text)
    end

    # add a couple more

    15.times do
      log_text = rand(9999999).to_s
      @db.write_to_log(99,log_text)
    end

    # check if there are eventually just enough log lines still in the database
    expect(Log.count).to eq(@db.max_nr_log_lines)
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
