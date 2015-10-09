class CreatePlantTable < ActiveRecord::Migration
  def change
    create_table :plants do |t|
      t.string :id_on_web_app
      t.integer :x
      t.integer :y
    end
  end
end
