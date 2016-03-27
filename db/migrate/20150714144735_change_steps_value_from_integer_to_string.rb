class ChangeStepsValueFromIntegerToString < ActiveRecord::Migration
  def change
    change_column :steps, :value, :text
  end
end
