require 'bson'
require 'sqlite3'
require 'active_record'

require_relative '../../app/models/log.rb'

# retrieving and inserting commands into the schedule queue for the farm bot
# using sqlite

# Access class for the database

class DbAccessLogs

  attr_writer   :dbaccess
  attr_accessor :log_to_screen

  def initialize
    @log_to_screen = true
  end

  ## logs

  # write a line to the log
  #
  def write_to_log(module_id,text)

    if @log_to_screen
      puts "[LOG] #{text}"
    end

    log           = Log.new
    log.text      = text
    log.module_id = module_id

    $db_write_sync.synchronize do
      log.save
    end

    # clean up old logs
    Log.where("created_at < (?)", 2.days.ago).find_each do |log|
      $db_write_sync.synchronize do
        log.delete
      end
    end
  end

  # read all logs from the log file
  #
  def read_logs_all()
    #logs = Log.find(:all, :order => 'created_at asc')
    logs = Log.all.order('created_at asc')
  end

  # read from the log file
  #
  def retrieve_log(module_id, nr_of_lines)
    #logs = Log.find(:all, :conditions => [ "module_id = (?)", module_id ], :order => 'created_at asc', :limit => nr_of_lines)
    logs = Log.where("module_id = (?)", module_id).order('created_at asc').first(nr_of_lines)
  end

  # disable putting text on the screen
  #
  def disable_log_to_screen
    @log_to_screen = false
  end

end
