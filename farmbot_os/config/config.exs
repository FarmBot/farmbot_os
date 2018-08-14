# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Mix configs.
target = Mix.Project.config()[:target]
env = Mix.env()

config :logger, [
  utc_log: true,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  backends: [:console]
]

# Randomly picked 300 megabytes.
# 3964928 bytes == ~4 megabytes in sqlite3
# 9266 logs = ~4 megabytes
# 4 logs * 75 = 300 megabytes
# 9266 logs * 75 = 694950 logs
# This will trim 175000 logs (25%) every time it gets to the max logs.
config :logger_backend_ecto, max_logs: 700000

# Customize non-Elixir parts of the firmware.  See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.
config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.
config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  handler: Farmbot.OS.ShoehornHandler,
  app: Mix.Project.config()[:app]

# Stop lager redirecting :error_logger messages
config :lager, :error_logger_redirect, false

# Stop lager removing Logger's :error_logger handler
config :lager, :error_logger_whitelist, []

# Stop lager writing a crash log
config :lager, :crash_log, false

# Use LagerLogger as lager's only handler.
config :lager, :handlers, []

config :ssl, protocol_version: :"tlsv1.2"

# Disable tzdata autoupdates because it tries to dl the update file
# Before we have network or ntp.
config :tzdata, :autoupdate, :disabled

config :farmbot_core, :behaviour,
  firmware_handler: Farmbot.Firmware.StubHandler,
  leds_handler: Farmbot.Leds.StubHandler,
  pin_binding_handler: Farmbot.PinBinding.StubHandler,
  celery_script_io_layer: Farmbot.OS.IOLayer,
  json_parser: Farmbot.JSON.JasonParser

config :farmbot_core,
  expected_fw_versions: ["6.4.0.F", "6.4.0.R", "6.4.0.G"],
  default_server: "https://my.farm.bot",
  default_currently_on_beta: String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta"),
  firmware_io_logs: false,
  farm_event_debug_log: false

config :farmbot_ext, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization,
  http_adapter:  Farmbot.HTTP.HTTPoisonAdapter

config :farmbot_os,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo]

config :farmbot_os, :builtins,
  sequence: [
    emergency_lock: -1,
    emergency_unlock: -2,
    sync: -3,
    reboot: -4,
    power_off: -5
  ],
  pin_binding: [
    emergency_lock: -1,
    emergency_unlock: -2,
  ]

case target do
  "host" ->
    import_config("host/#{env}.exs")

  _ ->
    import_config("target/#{env}.exs")
    if File.exists?("config/target/#{target}.exs"),
      do: import_config("target/#{target}.exs")
end
