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
  Farmbot.System.Debug
]

# Transports.
config :farmbot, :transport, [
  Farmbot.BotState.Transport.AMQP,
  Farmbot.BotState.Transport.HTTP,
  Farmbot.BotState.Transport.Registry,
]

config :farmbot, ecto_repos: [Farmbot.Repo, Farmbot.System.ConfigStorage]

config :farmbot, Farmbot.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "tmp/#{Farmbot.Repo}_dev.sqlite3"

config :farmbot, Farmbot.System.ConfigStorage,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "tmp/#{Farmbot.System.ConfigStorage}_dev.sqlite3"

config :farmbot, :farmware, first_part_farmware_manifest_url: nil
config :farmbot, default_server: "https://staging.farm.bot"

# Configure Farmbot Behaviours.
# Default Authorization behaviour.
# SystemTasks for host mode.
config :farmbot, :behaviour, [
  authorization: Farmbot.Bootstrap.Authorization,
  system_tasks: Farmbot.Host.SystemTasks,
  update_handler: Farmbot.Host.UpdateHandler,
  # firmware_handler: Farmbot.Firmware.UartHandler
]

config :farmbot, :uart_handler, tty: "/dev/ttyACM0"
