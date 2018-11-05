use Mix.Config
config :ecto, json_library: Farmbot.JSON

config :farmbot_core,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo]

config :farmbot_core, Farmbot.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "config.#{Mix.env()}.db",
  priv: "priv/config"

config :farmbot_core, Farmbot.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "logger.#{Mix.env()}.db",
  priv: "priv/logger"

config :farmbot_core, Farmbot.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "asset.#{Mix.env()}.db",
  priv: "priv/asset"
