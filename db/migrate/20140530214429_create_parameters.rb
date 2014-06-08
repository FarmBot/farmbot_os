class CreateParameters < ActiveRecord::Migration
  def change
    create_table :parameters do |t|
      t.string :name
      t.integer :valuetype
      t.integer :valueint
      t.float :valuefloat
      t.string :valuestring

      t.timestamps
    end
  end
end
