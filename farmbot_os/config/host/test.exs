use Mix.Config

data_path = Path.join(["/", "tmp", "farmbot"])
File.mkdir_p(data_path)

config :farmbot_ext,
  data_path: data_path

config :logger_backend_ecto, LoggerBackendEcto.Repo,
  adapter: Sqlite.Ecto2,
  database: Path.join(data_path, "logs.sqlite3")

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

config :farmbot, FarmbotOS.FirmwareTTYDetector, expected_names: []

config :farmbot_ext, FarmbotExt.AMQP.NervesHubTransport,
  handle_nerves_hub_msg: FarmbotOS.NervesHub

config :farmbot, FarmbotOS.NervesHub,
  farmbot_nerves_hub_handler: FarmbotOS.Platform.Host.NervesHubHandler
