# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Stop lager redirecting :error_logger messages
config :lager, :error_logger_redirect, false

# Stop lager removing Logger's :error_logger handler
config :lager, :error_logger_whitelist, []

# Stop lager writing a crash log
config :lager, :crash_log, false

# Use LagerLogger as lager's only handler.
config :lager, :handlers, []

config :ssl, protocol_version: :"tlsv1.2"

config :farmbot_core, :behaviour,
  firmware_handler: Farmbot.Firmware.StubHandler,
  leds_handler: Farmbot.Leds.StubHandler,
  pin_binding_handler: Farmbot.PinBinding.StubHandler,
  celery_script_io_layer: Farmbot.CeleryScript.StubIOLayer,
  json_parser: Farmbot.JSON.JasonParser

config :farmbot_core,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo],
  expected_fw_versions: ["6.4.0.F", "6.4.0.R", "6.4.0.G"],
  default_server: "https://my.farm.bot",
  default_currently_on_beta: String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta"),
  firmware_io_logs: false,
  farm_event_debug_log: false

config :farmbot_core, Farmbot.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: ".#{Mix.env}_configs.sqlite3",
  priv: "../farmbot_core/priv/config"

config :farmbot_core, Farmbot.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: ".#{Mix.env}_logs.sqlite3",
  priv: "../farmbot_core/priv/logger"

config :farmbot_core, Farmbot.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: ".#{Mix.env}_assets.sqlite3",
  priv: "../farmbot_core/priv/asset"

config :farmbot_ext, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization

config :farmbot_ext,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo],
  data_path: "/tmp"
