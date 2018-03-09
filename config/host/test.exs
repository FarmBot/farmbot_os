use Mix.Config

cond do
  System.get_env("CIRCLECI") ->
    Mix.shell.info [:green, "Using circle ci config."]
    import_config("auth_secret_ci.exs")
  File.exists?("config/host/auth_secret_test.exs") ->
    import_config("auth_secret_test.exs")
  true ->
    Mix.raise("You need to configure your test environment.\r\n")
end

config :farmbot, data_path: "test_tmp/"

config :farmbot, :init, [
  Farmbot.Host.Bootstrap.Configurator,
]

# Transports.
config :farmbot, :transport, [
  Farmbot.BotState.Transport.Test
]

config :farmbot, :farmware, first_part_farmware_manifest_url: nil

# Configure Farmbot Behaviours.
# config :farmbot, :behaviour,
  # authorization: Farmbot.Test.Authorization,

config :farmbot, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization,
  system_tasks: Farmbot.Test.SystemTasks,
  update_handler: FarmbotTestSupport.TestUpdateHandler


config :farmbot, Farmbot.Repo.A,
  adapter: Sqlite.Ecto2,
  database: "test_tmp/farmbot_repo_a_test",
  priv: "priv/repo",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 2,
  loggers: []

config :farmbot, Farmbot.Repo.B,
  adapter: Sqlite.Ecto2,
  database: "test_tmp/farmbot_repo_b_test",
  priv: "priv/repo",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 2,
  loggers: []

config :farmbot, Farmbot.System.ConfigStorage,
  adapter: Sqlite.Ecto2,
  database: "test_tmp/farmbot_config_storage_test",
  pool_size: 10,
  loggers: []

config :farmbot, ecto_repos: [Farmbot.Repo.A, Farmbot.Repo.B, Farmbot.System.ConfigStorage]
