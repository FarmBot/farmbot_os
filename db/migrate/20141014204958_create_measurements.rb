class CreateMeasurements < ActiveRecord::Migration
  def change
    create_table :measurements do |t|
      t.string :external_info
      t.float :value

      t.timestamps
    end
  end
end
