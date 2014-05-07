class CreateCommands < ActiveRecord::Migration
  def change
    create_table :commands do |t|
      t.integer :plant_id
      t.integer :crop_id
      t.datetime :scheduled_time
      t.datetime :executed_time
      t.string :status

      t.timestamps
    end
  end
end
