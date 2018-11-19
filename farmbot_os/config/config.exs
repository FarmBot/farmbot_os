use Mix.Config

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmEvent, checkup_time_ms: 10_000
config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.PersistentRegimen, checkup_time_ms: 10_000

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmwareInstallation,
  error_retry_time_ms: 30_000,
  install_dir: "/tmp/farmware"

config :farmbot_core, Elixir.Farmbot.AssetWorker.Farmbot.Asset.PinBinding,
  gpio_handler: Farmbot.PinBindingWorker.StubGPIOHandler,
  error_retry_time_ms: 30_000

# Customize non-Elixir parts of the firmware.  See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.
config :nerves, :firmware,
  rootfs_overlay: "rootfs_overlay",
  provisioning: :nerves_hub

config :farmbot_core, Farmbot.AssetMonitor, checkup_time_ms: 30_000

config :farmbot_core,
  expected_fw_versions: ["6.4.0.F", "6.4.0.R", "6.4.0.G"],
  default_firmware_io_logs: false,
  default_server: "https://my.farm.bot",
  default_currently_on_beta:
    String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta")

# Configure Farmbot Behaviours.
config :farmbot_core, :behaviour,
  leds_handler: Farmbot.Leds.StubHandler,
  celery_script_io_layer: Farmbot.OS.IOLayer,
  json_parser: Farmbot.JSON.JasonParser

config :farmbot_ext, :behaviour, authorization: Farmbot.Bootstrap.Authorization
config :ecto, json_library: Farmbot.JSON

config :farmbot_os,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo]

config :farmbot_core, Farmbot.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "config.#{Mix.env()}.db",
  priv: "../farmbot_core/priv/config"

config :farmbot_core, Farmbot.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "logger.#{Mix.env()}.db",
  priv: "../farmbot_core/priv/logger"

config :farmbot_core, Farmbot.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "asset.#{Mix.env()}.db",
  priv: "../farmbot_core/priv/asset"

config :farmbot_os, Farmbot.OS.FileSystem, data_path: "/tmp/farmbot"
config :farmbot_os, Farmbot.System, system_tasks: Farmbot.Host.SystemTasks

config :farmbot_os, Farmbot.Platform.Supervisor,
  platform_children: [
    Farmbot.Host.Configurator
  ]

import_config("lagger.exs")
