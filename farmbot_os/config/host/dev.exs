use Mix.Config

data_path = Path.join(["/", "tmp", "farmbot"])
File.mkdir_p(data_path)

config :farmbot_ext,
  data_path: data_path

config :logger_backend_ecto, LoggerBackendEcto.Repo,
  adapter: Sqlite.Ecto2,
  database: Path.join(data_path, "logs.sqlite3")

config :farmbot_core, Farmbot.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "config-#{Mix.env()}.sqlite3")

config :farmbot_core, Farmbot.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "logs-#{Mix.env()}.sqlite3")

config :farmbot_core, Farmbot.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "asset-#{Mix.env()}.sqlite3")

config :farmbot, Farmbot.System.Init.Supervisor,
  init_children: [
    Farmbot.TTYDetector,
    Farmbot.Host.Configurator
  ]

config :farmbot, :behaviour, system_tasks: Farmbot.Host.SystemTasks

config :farmbot,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo]

config :farmbot, Farmbot.System.NervesHub,
  farmbot_nerves_hub_handler: Farmbot.Host.NervesHubHandler
