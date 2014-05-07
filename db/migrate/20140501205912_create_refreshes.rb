class CreateRefreshes < ActiveRecord::Migration
  def change
    create_table :refreshes do |t|
      t.string :name
      t.integer :value

      t.timestamps
    end
  end
end
