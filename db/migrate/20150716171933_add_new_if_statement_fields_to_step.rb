class AddNewIfStatementFieldsToStep < ActiveRecord::Migration
  def change
    add_column :steps, :operator, :string
    add_column :steps, :variable, :string
    add_column :steps, :sub_sequence_id, :string
    add_column :sequences, :id_on_web_app, :string
  end
end
