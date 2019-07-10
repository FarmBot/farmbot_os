use Mix.Config

data_path = Path.join(["/", "tmp", "farmbot"])
File.mkdir_p(data_path)

config :farmbot_ext,
  data_path: data_path

config :farmbot_core, FarmbotCore.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "config-#{Mix.env()}.sqlite3")

config :farmbot_core, FarmbotCore.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "logs-#{Mix.env()}.sqlite3")

config :farmbot_core, FarmbotCore.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "asset-#{Mix.env()}.sqlite3")

config :farmbot,
  ecto_repos: [FarmbotCore.Config.Repo, FarmbotCore.Logger.Repo, FarmbotCore.Asset.Repo],
  platform_children: [
    {Farmbot.Platform.Host.Configurator, []}
  ]

config :farmbot, FarmbotOS.Configurator,
  data_layer: FarmbotTest.Configurator.MockDataLayer,
  network_layer: FarmbotTest.Configurator.MockNetworkLayer

config :farmbot_core, FarmbotCore.FirmwareTTYDetector, expected_names: []

config :farmbot_core, FarmbotCore.FirmwareOpenTask, attempt_threshold: 0

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.FbosConfig,
  firmware_flash_attempt_threshold: 0

config :plug, :validate_header_keys_during_test, true
