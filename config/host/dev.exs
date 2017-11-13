use Mix.Config

unless File.exists?("config/host/auth_secret.exs") do
  Mix.raise(
    "You need to configure your dev environment. See `config/host/auth_secret.exs` for an example.\r\n"
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
  Farmbot.BotState.Transport.GenMQTT,
  # Farmbot.BotState.Transport.AMQP,
  Farmbot.BotState.Transport.HTTP,
]

repos = [Farmbot.Repo.A, Farmbot.Repo.B, Farmbot.System.ConfigStorage]
config :farmbot, ecto_repos: repos

for repo <- [Farmbot.Repo.A, Farmbot.Repo.B] do
  config :farmbot, repo,
    adapter: Sqlite.Ecto2,
    loggers: [],
    database: "tmp/#{repo}_dev.sqlite3"
end

config :farmbot, Farmbot.System.ConfigStorage,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "tmp/#{Farmbot.System.ConfigStorage}_dev.sqlite3"

# Configure Farmbot Behaviours.
# Default Authorization behaviour.
# SystemTasks for host mode.
config :farmbot, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization,
  system_tasks: Farmbot.Host.SystemTasks
  # firmware_handler: Farmbot.Firmware.UartHandler

config :farmbot, :uart_handler, tty: "/dev/ttyACM0"
