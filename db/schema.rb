# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150714144735) do

  create_table "schedules", force: :cascade do |t|
    t.integer  "sequence_id"
    t.string   "id_on_web_app"
    t.string   "time_unit"
    t.float    "repeat"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "next_time"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "sequences", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "steps", force: :cascade do |t|
    t.string   "message_type"
    t.integer  "x"
    t.integer  "y"
    t.integer  "z"
    t.integer  "speed"
    t.integer  "pin"
    t.text     "value"
    t.integer  "mode"
    t.integer  "sequence_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "position"
  end

end
