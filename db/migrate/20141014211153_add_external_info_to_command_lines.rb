class AddExternalInfoToCommandLines < ActiveRecord::Migration
  def change
    add_column :command_lines, :external_info     , :string
  end
end
