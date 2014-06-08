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

ActiveRecord::Schema.define(version: 20140530214429) do

  create_table "command_lines", force: true do |t|
    t.integer  "command_id"
    t.string   "action"
    t.float    "coord_x"
    t.float    "coord_y"
    t.float    "coord_z"
    t.string   "speed"
    t.float    "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "commands", force: true do |t|
    t.integer  "plant_id"
    t.integer  "crop_id"
    t.datetime "scheduled_time"
    t.datetime "executed_time"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "logs", force: true do |t|
    t.integer  "module_id"
    t.string   "text"
    t.datetime "time_stamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "parameters", force: true do |t|
    t.string   "name"
    t.integer  "valuetype"
    t.integer  "valueint"
    t.float    "valuefloat"
    t.string   "valuestring"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "refreshes", force: true do |t|
    t.string   "name"
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
