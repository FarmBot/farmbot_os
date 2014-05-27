class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.integer :module_id
      t.string :text
      t.datetime :time_stamp

      t.timestamps
    end
  end
end
