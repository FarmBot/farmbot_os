defmodule FarmbotOS.Asset.Repo.Migrations.InitialMigration do
  use Ecto.Migration

  def up do
    execute(
      "CREATE TABLE IF NOT EXISTS \"bool_values\" (\"id\" INTEGER PRIMARY KEY, \"value\" BOOLEAN);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"configs\" (\"id\" INTEGER PRIMARY KEY, \"group_id\" INTEGER NOT NULL CONSTRAINT \"configs_group_id_fkey\" REFERENCES \"groups\"(\"id\"), \"string_value_id\" INTEGER CONSTRAINT \"configs_string_value_id_fkey\" REFERENCES \"string_values\"(\"id\"), \"bool_value_id\" INTEGER CONSTRAINT \"configs_bool_value_id_fkey\" REFERENCES \"bool_values\"(\"id\"), \"float_value_id\" INTEGER CONSTRAINT \"configs_float_value_id_fkey\" REFERENCES \"float_values\"(\"id\"), \"key\" TEXT);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"device_certs\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"serial_number\" TEXT, \"tags\" JSON, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"devices\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"name\" TEXT, \"timezone\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL, \"last_ota\" UTC_DATETIME, \"last_ota_checkup\" UTC_DATETIME, \"ota_hour\" INTEGER, \"mounted_tool_id\" INTEGER, \"needs_reset\" BOOLEAN DEFAULT 0, \"lat\" FLOAT, \"lng\" FLOAT, \"indoor\" BOOLEAN);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"farm_event_executions\" (\"local_id\" BINARY_ID PRIMARY KEY, \"farm_event_local_id\" BINARY_ID CONSTRAINT \"farm_event_executions_farm_event_local_id_fkey\" REFERENCES \"farm_events\"(\"local_id\"), \"scheduled_at\" UTC_DATETIME, \"executed_at\" UTC_DATETIME, \"status\" TEXT, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"farm_events\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"end_time\" UTC_DATETIME, \"executable_type\" TEXT, \"executable_id\" ID, \"repeat\" INTEGER, \"start_time\" UTC_DATETIME, \"time_unit\" TEXT, \"last_executed\" UTC_DATETIME, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL, \"body\" JSON);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"farmware_envs\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"key\" TEXT, \"value\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"farmware_installations\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"url\" TEXT, \"manifest\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"farmware_repositories\" (\"id\" INTEGER PRIMARY KEY, \"manifests\" TEXT, \"url\" TEXT);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"fbos_configs\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"arduino_debug_messages\" BOOLEAN, \"auto_sync\" BOOLEAN, \"beta_opt_in\" BOOLEAN, \"disable_factory_reset\" BOOLEAN, \"firmware_hardware\" TEXT, \"firmware_path\" TEXT, \"firmware_input_log\" BOOLEAN, \"firmware_output_log\" BOOLEAN, \"firmware_debug_log\" BOOLEAN, \"network_not_found_timer\" INTEGER, \"os_auto_update\" BOOLEAN, \"sequence_body_log\" BOOLEAN, \"sequence_complete_log\" BOOLEAN, \"sequence_init_log\" BOOLEAN, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL, \"update_channel\" TEXT, \"safe_height\" FLOAT, \"soil_height\" FLOAT);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"firmware_configs\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"pin_guard_4_time_out\" FLOAT, \"pin_guard_1_active_state\" FLOAT, \"encoder_scaling_y\" FLOAT, \"movement_invert_2_endpoints_x\" FLOAT, \"movement_min_spd_y\" FLOAT, \"pin_guard_2_time_out\" FLOAT, \"movement_timeout_y\" FLOAT, \"movement_home_at_boot_y\" FLOAT, \"movement_home_spd_z\" FLOAT, \"movement_invert_endpoints_z\" FLOAT, \"pin_guard_1_pin_nr\" FLOAT, \"movement_invert_endpoints_y\" FLOAT, \"movement_max_spd_y\" FLOAT, \"movement_home_up_y\" FLOAT, \"encoder_missed_steps_decay_z\" FLOAT, \"movement_home_spd_y\" FLOAT, \"encoder_use_for_pos_x\" FLOAT, \"movement_step_per_mm_x\" FLOAT, \"movement_home_at_boot_z\" FLOAT, \"movement_steps_acc_dec_z\" FLOAT, \"pin_guard_5_pin_nr\" FLOAT, \"movement_invert_motor_z\" FLOAT, \"movement_max_spd_x\" FLOAT, \"movement_enable_endpoints_y\" FLOAT, \"movement_enable_endpoints_z\" FLOAT, \"movement_stop_at_home_x\" FLOAT, \"movement_axis_nr_steps_y\" FLOAT, \"pin_guard_1_time_out\" FLOAT, \"movement_home_at_boot_x\" FLOAT, \"pin_guard_2_pin_nr\" FLOAT, \"encoder_scaling_z\" FLOAT, \"param_e_stop_on_mov_err\" FLOAT, \"encoder_enabled_x\" FLOAT, \"pin_guard_2_active_state\" FLOAT, \"encoder_missed_steps_decay_y\" FLOAT, \"movement_home_up_z\" FLOAT, \"movement_enable_endpoints_x\" FLOAT, \"movement_step_per_mm_y\" FLOAT, \"pin_guard_3_pin_nr\" FLOAT, \"param_mov_nr_retry\" FLOAT, \"movement_stop_at_home_z\" FLOAT, \"pin_guard_4_active_state\" FLOAT, \"movement_steps_acc_dec_y\" FLOAT, \"movement_home_spd_x\" FLOAT, \"movement_keep_active_x\" FLOAT, \"pin_guard_3_time_out\" FLOAT, \"movement_keep_active_y\" FLOAT, \"encoder_scaling_x\" FLOAT, \"movement_invert_2_endpoints_z\" FLOAT, \"encoder_missed_steps_decay_x\" FLOAT, \"movement_timeout_z\" FLOAT, \"encoder_missed_steps_max_z\" FLOAT, \"movement_min_spd_z\" FLOAT, \"encoder_enabled_y\" FLOAT, \"encoder_type_y\" FLOAT, \"movement_home_up_x\" FLOAT, \"pin_guard_3_active_state\" FLOAT, \"movement_invert_motor_x\" FLOAT, \"movement_keep_active_z\" FLOAT, \"movement_max_spd_z\" FLOAT, \"movement_secondary_motor_invert_x\" FLOAT, \"movement_stop_at_max_x\" FLOAT, \"movement_steps_acc_dec_x\" FLOAT, \"pin_guard_4_pin_nr\" FLOAT, \"encoder_type_x\" FLOAT, \"movement_invert_2_endpoints_y\" FLOAT, \"encoder_invert_y\" FLOAT, \"movement_axis_nr_steps_x\" FLOAT, \"movement_stop_at_max_z\" FLOAT, \"movement_invert_endpoints_x\" FLOAT, \"encoder_invert_z\" FLOAT, \"encoder_use_for_pos_z\" FLOAT, \"pin_guard_5_active_state\" FLOAT, \"movement_step_per_mm_z\" FLOAT, \"encoder_enabled_z\" FLOAT, \"movement_secondary_motor_x\" FLOAT, \"pin_guard_5_time_out\" FLOAT, \"movement_min_spd_x\" FLOAT, \"encoder_type_z\" FLOAT, \"movement_stop_at_max_y\" FLOAT, \"encoder_use_for_pos_y\" FLOAT, \"encoder_missed_steps_max_y\" FLOAT, \"movement_timeout_x\" FLOAT, \"movement_stop_at_home_y\" FLOAT, \"movement_axis_nr_steps_z\" FLOAT, \"encoder_invert_x\" FLOAT, \"encoder_missed_steps_max_x\" FLOAT, \"movement_invert_motor_y\" FLOAT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL, \"api_migrated\" BOOLEAN, \"movement_motor_current_x\" FLOAT, \"movement_motor_current_y\" FLOAT, \"movement_motor_current_z\" FLOAT, \"movement_stall_sensitivity_x\" FLOAT, \"movement_stall_sensitivity_y\" FLOAT, \"movement_stall_sensitivity_z\" FLOAT, \"movement_microsteps_x\" FLOAT, \"movement_microsteps_y\" FLOAT, \"movement_microsteps_z\" FLOAT, \"movement_max_spd_z2\" FLOAT, \"movement_min_spd_z2\" FLOAT, \"movement_steps_acc_dec_z2\" FLOAT, \"movement_calibration_retry_x\" FLOAT, \"movement_calibration_retry_y\" FLOAT, \"movement_calibration_retry_z\" FLOAT, \"movement_calibration_deadzone_x\" FLOAT, \"movement_calibration_deadzone_y\" FLOAT, \"movement_calibration_deadzone_z\" FLOAT, \"movement_axis_stealth_x\" FLOAT, \"movement_axis_stealth_y\" FLOAT, \"movement_axis_stealth_z\" FLOAT);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"first_party_farmwares\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"url\" TEXT, \"manifest\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"float_values\" (\"id\" INTEGER PRIMARY KEY, \"value\" FLOAT);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"gpio_registry\" (\"id\" INTEGER PRIMARY KEY, \"pin\" INTEGER, \"sequence_id\" INTEGER);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"groups\" (\"id\" INTEGER PRIMARY KEY, \"group_name\" TEXT);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"local_metas\" (\"id\" INTEGER PRIMARY KEY, \"status\" TEXT, \"table\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"asset_local_id\" BINARY_ID);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"logs\" (\"id\" BINARY_ID PRIMARY KEY, \"message\" TEXT, \"level\" TEXT, \"verbosity\" INTEGER, \"meta\" TEXT, \"function\" TEXT, \"file\" TEXT, \"line\" INTEGER, \"module\" TEXT, \"version\" TEXT, \"commit\" TEXT, \"target\" TEXT, \"env\" TEXT, \"inserted_at\" NAIVE_DATETIME NOT NULL, \"updated_at\" NAIVE_DATETIME NOT NULL, \"hash\" BINARY, \"duplicates\" INTEGER);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"network_interfaces\" (\"id\" INTEGER PRIMARY KEY, \"name\" TEXT NOT NULL, \"type\" TEXT NOT NULL, \"ssid\" TEXT, \"psk\" TEXT, \"security\" TEXT, \"ipv4_method\" TEXT, \"migrated\" BOOLEAN, \"maybe_hidden\" BOOLEAN, \"ipv4_address\" TEXT, \"ipv4_gateway\" TEXT, \"ipv4_subnet_mask\" TEXT, \"domain\" TEXT, \"name_servers\" TEXT, \"regulatory_domain\" TEXT DEFAULT 'US', \"identity\" TEXT, \"password\" TEXT);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"peripherals\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"pin\" INTEGER, \"mode\" INTEGER, \"label\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"persistent_regimens\" (\"id\" INTEGER PRIMARY KEY, \"regimen_id\" INTEGER, \"time\" UTC_DATETIME, \"farm_event_id\" INTEGER);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"pin_bindings\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"pin_num\" INTEGER, \"sequence_id\" INTEGER, \"special_action\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"point_groups\" (\"local_id\" BINARY_ID PRIMARY KEY, \"monitor\" BOOLEAN DEFAULT 1, \"id\" ID, \"name\" TEXT, \"point_ids\" JSON, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL, \"sort_type\" TEXT, \"criteria\" TEXT);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"points\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"meta\" TEXT, \"name\" TEXT, \"plant_stage\" TEXT, \"planted_at\" UTC_DATETIME, \"pointer_type\" TEXT, \"radius\" FLOAT, \"x\" FLOAT, \"y\" FLOAT, \"z\" FLOAT, \"tool_id\" INTEGER, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL, \"discarded_at\" UTC_DATETIME, \"gantry_mounted\" BOOLEAN DEFAULT 0, \"openfarm_slug\" TEXT, \"pullout_direction\" INTEGER DEFAULT 0);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"public_keys\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"name\" TEXT, \"public_key\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"regimen_instance_executions\" (\"local_id\" BINARY_ID PRIMARY KEY, \"regimen_instance_local_id\" BINARY_ID CONSTRAINT \"regimen_instance_executions_regimen_instance_local_id_fkey\" REFERENCES \"regimen_instances\"(\"local_id\"), \"scheduled_at\" UTC_DATETIME, \"executed_at\" UTC_DATETIME, \"status\" TEXT, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"regimen_instances\" (\"local_id\" BINARY_ID PRIMARY KEY, \"started_at\" UTC_DATETIME, \"epoch\" UTC_DATETIME, \"next\" UTC_DATETIME, \"next_sequence_id\" ID, \"regimen_id\" BINARY_ID CONSTRAINT \"persistent_regimens_regimen_id_fkey\" REFERENCES \"regimens\"(\"local_id\"), \"farm_event_id\" BINARY_ID CONSTRAINT \"persistent_regimens_farm_event_id_fkey\" REFERENCES \"farm_events\"(\"local_id\"), \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"regimens\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"regimen_items\" JSON, \"name\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL, \"body\" JSON);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"sensor_readings\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"mode\" INTEGER, \"pin\" INTEGER, \"value\" INTEGER, \"x\" FLOAT, \"y\" FLOAT, \"z\" FLOAT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"sensors\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"pin\" INTEGER, \"mode\" INTEGER, \"label\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"sequences\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"name\" TEXT, \"kind\" TEXT, \"args\" TEXT, \"body\" JSON, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"string_values\" (\"id\" INTEGER PRIMARY KEY, \"value\" TEXT);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"sync_cmds\" (\"id\" INTEGER PRIMARY KEY, \"remote_id\" INTEGER, \"kind\" TEXT, \"body\" TEXT, \"inserted_at\" NAIVE_DATETIME NOT NULL, \"updated_at\" NAIVE_DATETIME NOT NULL);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"syncs\" (\"local_id\" BINARY_ID PRIMARY KEY, \"devices\" JSON, \"farm_events\" JSON, \"farmware_envs\" JSON, \"farmware_installations\" JSON, \"fbos_configs\" JSON, \"firmware_configs\" JSON, \"peripherals\" JSON, \"pin_bindings\" JSON, \"points\" JSON, \"regimens\" JSON, \"sensor_readings\" JSON, \"sensors\" JSON, \"sequences\" JSON, \"tools\" JSON, \"now\" UTC_DATETIME, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL, \"public_keys\" JSON, \"first_party_farmwares\" JSON, \"point_groups\" JSON);"
    )

    execute(
      "CREATE TABLE IF NOT EXISTS \"tools\" (\"local_id\" BINARY_ID PRIMARY KEY, \"id\" ID, \"name\" TEXT, \"monitor\" BOOLEAN DEFAULT 1, \"created_at\" UTC_DATETIME NOT NULL, \"updated_at\" UTC_DATETIME NOT NULL);"
    )

    execute("CREATE UNIQUE INDEX \"devices_id_index\" ON \"devices\" (\"id\");")

    execute(
      "CREATE UNIQUE INDEX \"farm_events_id_index\" ON \"farm_events\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"farmware_envs_id_index\" ON \"farmware_envs\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"farmware_installations_id_index\" ON \"farmware_installations\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"farmware_repositories_url_index\" ON \"farmware_repositories\" (\"url\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"fbos_configs_id_index\" ON \"fbos_configs\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"firmware_configs_id_index\" ON \"firmware_configs\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"first_party_farmwares_id_index\" ON \"first_party_farmwares\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"local_metas_table_asset_local_id_index\" ON \"local_metas\" (\"table\", \"asset_local_id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"network_interfaces_name_index\" ON \"network_interfaces\" (\"name\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"peripherals_id_index\" ON \"peripherals\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"pin_bindings_id_index\" ON \"pin_bindings\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"point_groups_id_index\" ON \"point_groups\" (\"id\");"
    )

    execute("CREATE UNIQUE INDEX \"points_id_index\" ON \"points\" (\"id\");")

    execute(
      "CREATE UNIQUE INDEX \"public_keys_id_index\" ON \"public_keys\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"regimens_id_index\" ON \"regimens\" (\"id\");"
    )

    execute(
      "CREATE UNIQUE INDEX \"sensor_readings_id_index\" ON \"sensor_readings\" (\"id\");"
    )

    execute("CREATE UNIQUE INDEX \"sensors_id_index\" ON \"sensors\" (\"id\");")

    execute(
      "CREATE UNIQUE INDEX \"sequences_id_index\" ON \"sequences\" (\"id\");"
    )

    execute("CREATE UNIQUE INDEX \"tools_id_index\" ON \"tools\" (\"id\");")
  end
end
