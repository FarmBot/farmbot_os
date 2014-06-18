class AddValueBoolToParameters < ActiveRecord::Migration
  def change
    add_column :parameters, :valuebool, :boolean
  end
end
