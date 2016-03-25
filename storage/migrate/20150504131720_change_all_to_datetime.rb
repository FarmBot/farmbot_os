class ChangeAllToDatetime < ActiveRecord::Migration
  def change
    change_column :schedules, :start_time, :datetime
    change_column :schedules, :end_time, :datetime
    change_column :schedules, :next_time, :datetime
  end
end
