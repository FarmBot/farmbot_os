use Mix.Config

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler

config :farmbot_core,
       Elixir.FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey,
       ssh_handler: FarmbotCore.PublicKeyHandler.StubSSHHandler

config :farmbot_core, FarmbotCore.Leds,
  gpio_handler: FarmbotCore.Leds.StubHandler

config :farmbot_core, FarmbotCore.JSON,
  json_parser: FarmbotCore.JSON.JasonParser

config :farmbot_core, FarmbotCore.BotState.FileSystem, root_dir: "/tmp/farmbot"

config :farmbot_core, FarmbotCore.EctoMigrator,
  default_firmware_io_logs: false,
  default_server: "https://my.farm.bot",
  default_dns_name: "my.farm.bot",
  default_ntp_server_1: "0.pool.ntp.org",
  default_ntp_server_2: "1.pool.ntp.org",
  default_currently_on_beta:
    String.contains?(
      to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')),
      "beta"
    )

config :ecto, json_library: FarmbotCore.JSON

config :farmbot_core,
  ecto_repos: [
    FarmbotCore.Config.Repo,
    FarmbotCore.Logger.Repo,
    FarmbotCore.Asset.Repo
  ]

config :farmbot_core, FarmbotCore.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "config.#{Mix.env()}.db",
  priv: "priv/config"

config :farmbot_core, FarmbotCore.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "logger.#{Mix.env()}.db",
  priv: "priv/logger"

config :farmbot_core, FarmbotCore.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "asset.#{Mix.env()}.db",
  priv: "priv/asset"

config :logger,
  handle_otp_reports: false,
  handle_sasl_reports: false

import_config "#{Mix.env()}.exs"
