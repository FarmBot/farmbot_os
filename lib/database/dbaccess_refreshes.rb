require 'bson'
require 'sqlite3'
require 'active_record'

require './app/models/refresh.rb'

# retrieving and inserting commands into the schedule queue for the farm bot
# using sqlite

# Access class for the database

class DbAccessRefreshes

  attr_writer :dbaccess

  def initialize
    @refresh_value = 0
    @refresh_value_new = 0
  end

  ## refreshes

  def check_refresh
    r = Refresh.find_or_create_by(name: 'FarmBotControllerSchedule')
    @refresh_value_new = (r == nil ? 0 : r.value.to_i)
    return @refresh_value_new != @refresh_value
  end

  def save_refresh
    @refresh_value = @refresh_value_new
  end

  def increment_refresh
    r = Refresh.find_or_create_by(name: 'FarmBotControllerSchedule')
    r.value = r.value == nil ? 0 : r.value.to_i + 1
    $db_write_sync.synchronize do
      r.save
    end
  end

end
