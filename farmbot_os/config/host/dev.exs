use Mix.Config

data_path = Path.join(["/", "tmp", "farmbot"])
File.mkdir_p(data_path)

config :farmbot_ext,
  data_path: data_path

config :farmbot_core, FarmbotCore.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  pool_size: 1,
  database: Path.join(data_path, "config-#{Mix.env()}.sqlite3")

config :farmbot_core, FarmbotCore.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  pool_size: 1,
  database: Path.join(data_path, "logs-#{Mix.env()}.sqlite3")

config :farmbot_core, FarmbotCore.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  pool_size: 1,
  database: Path.join(data_path, "asset-#{Mix.env()}.sqlite3")

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.FirmwareTTYDetector,
    FarmbotOS.Platform.Host.Configurator
  ]

config :farmbot,
  ecto_repos: [FarmbotCore.Config.Repo, FarmbotCore.Logger.Repo, FarmbotCore.Asset.Repo]

config :farmbot, FarmbotOS.FirmwareTTYDetector,
  expected_names: [
    System.get_env("FARMBOT_TTY")
  ]
