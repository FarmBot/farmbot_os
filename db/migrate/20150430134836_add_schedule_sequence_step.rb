class AddScheduleSequenceStep < ActiveRecord::Migration
  def change
    create_table :sequences do |t|
      t.string :name
      t.timestamps null: false
    end

    create_table :schedules do |t|
      t.references :sequence
      t.string :repeat
      t.string :time_unit
      t.time :start_time
      t.time :end_time
      t.timestamps null: false
    end

    create_table :steps do |t|
      t.string  :message_type
      t.integer :x
      t.integer :y
      t.integer :z
      t.integer :speed
      t.integer :pin
      t.integer :value
      t.integer :mode
      t.references :sequence
      t.timestamps null: false
    end
  end
end
