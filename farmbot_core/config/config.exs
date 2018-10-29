use Mix.Config

config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: true

config :ecto, json_library: Farmbot.JSON

# Configure Farmbot Behaviours.
config :farmbot_core, :behaviour,
  firmware_handler: Farmbot.Firmware.StubHandler,
  leds_handler: Farmbot.Leds.StubHandler,
  pin_binding_handler: Farmbot.PinBinding.StubHandler,
  celery_script_io_layer: Farmbot.Core.CeleryScript.StubIOLayer,
  json_parser: Farmbot.JSON.JasonParser

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmEvent, checkup_time_ms: 10_000

config :farmbot_core, Farmbot.AssetMonitor, checkup_time_ms: 30_000

if Mix.env() == :test do
  config :farmbot_core, :behaviour,
    celery_script_io_layer: Farmbot.TestSupport.CeleryScript.TestIOLayer

  config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmEvent, checkup_time_ms: 1000

  # must be lower than other timers
  # To ensure other timers have time to timeout
  config :farmbot_core, Farmbot.AssetMonitor, checkup_time_ms: 500
end

config :farmbot_core,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo],
  expected_fw_versions: ["6.4.2.F", "6.4.2.R", "6.4.2.G"],
  default_server: "https://my.farm.bot",
  default_currently_on_beta:
    String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta"),
  firmware_io_logs: false,
  farm_event_debug_log: false

config :farmbot_core, Farmbot.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: ".#{Mix.env()}_configs.sqlite3",
  priv: "priv/config"

config :farmbot_core, Farmbot.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: ".#{Mix.env()}_logs.sqlite3",
  priv: "priv/logger"

config :farmbot_core, Farmbot.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: ".#{Mix.env()}_assets.sqlite3",
  priv: "priv/asset"
