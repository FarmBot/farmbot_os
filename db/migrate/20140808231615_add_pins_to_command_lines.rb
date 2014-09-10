class AddPinsToCommandLines < ActiveRecord::Migration
  def change
    add_column :command_lines, :pin_nr     , :integer
    add_column :command_lines, :pin_mode   , :integer
    add_column :command_lines, :pin_value_1, :integer
    add_column :command_lines, :pin_value_2, :integer
    add_column :command_lines, :pin_time   , :integer
  end
end
