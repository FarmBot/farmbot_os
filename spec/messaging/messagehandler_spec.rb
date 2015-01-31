require 'spec_helper'
require './lib/messaging/messaging.rb'

describe MessageHandler do

  before do
    $db_write_sync = Mutex.new
    $dbaccess = DbAccess.new('development')
    @msg = MessageHandler.new
  end

  ## messaging

  it "test" do
    expect(1).to eq(1)
  end

#  it "create new command" do
#    crop_id        = rand(9999999).to_i    
#    scheduled_time = Time.now
#
#    @db.create_new_command(scheduled_time, crop_id)
#
#    cmd = Command.where("scheduled_time = ?",scheduled_time).first
#
#    expect(cmd.crop_id).to eq(crop_id)
#  end

end
