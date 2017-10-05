use Mix.Config
unless File.exists?("config/host/auth_secret.exs") do
  Mix.raise("You need to configure your dev environment. See `config/host/auth_secret.exs` for an example.\r\n")
end

import_config("auth_secret.exs")

config :farmbot, data_path: "tmp/"

# Configure your our system.
# Default implementation needs no special stuff.
config :farmbot, :init, [
  Farmbot.Host.Bootstrap.Configurator,
]

# Transports.
config :farmbot, :transport, [
  # Farmbot.BotState.Transport.GenMQTT
]


# Configure Farmbot Behaviours.
config :farmbot, :behaviour, [
  # Default Authorization behaviour.
  authorization: Farmbot.Bootstrap.Authorization,
  # SystemTasks for host mode.
  system_tasks: Farmbot.Host.SystemTasks,

  # firmware_handler: Farmbot.Firmware.UartHandler
]

config :farmbot, :uart_handler, [
  tty: "/dev/ttyACM0"
]
