use Mix.Config

unless File.exists?("config/host/auth_secret.exs") do
  Mix.raise(
    "You need to configure your dev environment. See `config/host/auth_secret_template.exs` for an example.\r\n"
  )
end

import_config("auth_secret.exs")

config :farmbot, data_path: "tmp/"

# Configure your our system.
# Default implementation needs no special stuff.
config :farmbot, :init, [
  Farmbot.Host.Bootstrap.Configurator,
  Farmbot.Host.TargetConfiguratorTest.Supervisor,
  Farmbot.System.Debug
]

# Transports.
config :farmbot, :transport, [
  Farmbot.BotState.Transport.AMQP,
  Farmbot.BotState.Transport.HTTP,
]

repos = [Farmbot.Repo.A, Farmbot.Repo.B, Farmbot.System.ConfigStorage, Farmbot.System.GlobalConfig]
config :farmbot, ecto_repos: repos

config :farmbot, Farmbot.Repo.A,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "tmp/users/default/repo-A.sqlite3",
  pool_size: 1

config :farmbot, Farmbot.Repo.B,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "tmp/users/default/repo-B.sqlite3",
  pool_size: 1

config :farmbot, Farmbot.System.ConfigStorage,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "tmp/users/default/config.sqlite3",
  pool_size: 1

config :farmbot, Farmbot.System.GlobalConfig,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "tmp/global-config.sqlite3",
  pool_size: 1

# config :farmbot, :farmware, first_part_farmware_manifest_url: nil

# Configure Farmbot Behaviours.
# Default Authorization behaviour.
# SystemTasks for host mode.
config :farmbot, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization,
  system_tasks: Farmbot.Host.SystemTasks,
  update_handler: Farmbot.Host.UpdateHandler,
  firmware_handler: Farmbot.Firmware.UartHandler

config :farmbot, :uart_handler, tty: "/dev/ttyACM0"

config :farmbot, :logger, [
  # backends: [Elixir.Logger.Backends.Farmbot]
]
