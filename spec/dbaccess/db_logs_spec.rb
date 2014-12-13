require 'spec_helper'
require './lib/database/dbaccess.rb'

describe DbAccess do

  before do
    $db_write_sync = Mutex.new
    @db = DbAccess.new('development')
  end

  ## logs

#  def write_to_log(module_id,text)
#    @logs.write_to_log(module_id,text)
#  end

#  def read_logs_all()
#    @logs.read_logs_all()
#  end

#  def retrieve_log(module_id, nr_of_lines)
#    @logs.retrieve_log(module_id, nr_of_lines)
#  end

end
