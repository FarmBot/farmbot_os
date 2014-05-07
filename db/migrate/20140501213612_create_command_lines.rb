class CreateCommandLines < ActiveRecord::Migration
  def change
    create_table :command_lines do |t|
      t.integer :command_id
      t.string :action
      t.float :coord_x
      t.float :coord_y
      t.float :coord_z
      t.string :speed
      t.float :amount

      t.timestamps
    end
  end
end
