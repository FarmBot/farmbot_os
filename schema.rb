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

ActiveRecord::Schema.define(version: 20170818163411) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "devices", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "webcam_url"
    t.integer "max_log_count", default: 100
    t.integer "max_images_count", default: 100
    t.string "timezone", limit: 280
    t.datetime "last_seen"
    t.index ["timezone"], name: "index_devices_on_timezone"
  end

  create_table "farm_events", id: :serial, force: :cascade do |t|
    t.integer "device_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "repeat"
    t.string "time_unit"
    t.string "executable_type", limit: 280
    t.integer "executable_id"
    t.index ["device_id"], name: "index_farm_events_on_device_id"
    t.index ["executable_type", "executable_id"], name: "index_farm_events_on_executable_type_and_executable_id"
  end

  create_table "generic_pointers", id: :serial, force: :cascade do |t|
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.integer "device_id"
    t.text "meta"
    t.datetime "attachment_processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.integer "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.index ["device_id"], name: "index_images_on_device_id"
  end

  create_table "log_dispatches", force: :cascade do |t|
    t.bigint "device_id"
    t.bigint "log_id"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_log_dispatches_on_device_id"
    t.index ["log_id"], name: "index_log_dispatches_on_log_id"
    t.index ["sent_at"], name: "index_log_dispatches_on_sent_at"
  end

  create_table "logs", id: :serial, force: :cascade do |t|
    t.text "message"
    t.text "meta"
    t.string "channels", limit: 280
    t.integer "device_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_logs_on_device_id"
  end

  create_table "peripherals", id: :serial, force: :cascade do |t|
    t.integer "device_id"
    t.integer "pin"
    t.integer "mode"
    t.string "label", limit: 280
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_peripherals_on_device_id"
  end

  create_table "plants", id: :serial, force: :cascade do |t|
    t.string "openfarm_slug", limit: 280, default: "50", null: false
    t.datetime "created_at"
    t.index ["created_at"], name: "index_plants_on_created_at"
  end

  create_table "points", id: :serial, force: :cascade do |t|
    t.float "radius", default: 25.0, null: false
    t.float "x", null: false
    t.float "y", null: false
    t.float "z", default: 0.0, null: false
    t.integer "device_id", null: false
    t.hstore "meta"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "untitled", null: false
    t.string "pointer_type", limit: 280, null: false
    t.integer "pointer_id", null: false
    t.index ["device_id"], name: "index_points_on_device_id"
    t.index ["meta"], name: "index_points_on_meta", using: :gin
    t.index ["pointer_type", "pointer_id"], name: "index_points_on_pointer_type_and_pointer_id"
  end

  create_table "regimen_items", id: :serial, force: :cascade do |t|
    t.bigint "time_offset"
    t.integer "regimen_id"
    t.integer "sequence_id"
    t.index ["regimen_id"], name: "index_regimen_items_on_regimen_id"
    t.index ["sequence_id"], name: "index_regimen_items_on_sequence_id"
  end

  create_table "regimens", id: :serial, force: :cascade do |t|
    t.string "color"
    t.string "name", limit: 280
    t.integer "device_id"
    t.index ["device_id"], name: "index_regimens_on_device_id"
  end

  create_table "sequence_dependencies", id: :serial, force: :cascade do |t|
    t.string "dependency_type"
    t.integer "dependency_id"
    t.integer "sequence_id", null: false
    t.index ["dependency_id"], name: "index_sequence_dependencies_on_dependency_id"
    t.index ["dependency_type"], name: "index_sequence_dependencies_on_dependency_type"
    t.index ["sequence_id"], name: "index_sequence_dependencies_on_sequence_id"
  end

  create_table "sequences", id: :serial, force: :cascade do |t|
    t.integer "device_id"
    t.string "name", null: false
    t.string "color"
    t.string "kind", limit: 280, default: "sequence"
    t.text "args"
    t.text "body"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.index ["created_at"], name: "index_sequences_on_created_at"
    t.index ["device_id"], name: "index_sequences_on_device_id"
  end

  create_table "token_expirations", id: :serial, force: :cascade do |t|
    t.string "sub"
    t.integer "exp"
    t.string "jti"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tool_slots", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tool_id"
    t.index ["tool_id"], name: "index_tool_slots_on_tool_id"
  end

  create_table "tools", id: :serial, force: :cascade do |t|
    t.string "name", limit: 280
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "device_id"
    t.index ["device_id"], name: "index_tools_on_device_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.integer "device_id"
    t.string "name"
    t.string "email", limit: 280, default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.string "verification_token"
    t.datetime "agreed_to_terms_at"
    t.index ["agreed_to_terms_at"], name: "index_users_on_agreed_to_terms_at"
    t.index ["device_id"], name: "index_users_on_device_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "webcam_feeds", force: :cascade do |t|
    t.bigint "device_id"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_webcam_feeds_on_device_id"
  end

  add_foreign_key "log_dispatches", "devices"
  add_foreign_key "log_dispatches", "logs"
  add_foreign_key "peripherals", "devices"
  add_foreign_key "points", "devices"
  add_foreign_key "sequence_dependencies", "sequences"
  add_foreign_key "tool_slots", "tools"
end
