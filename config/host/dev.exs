use Mix.Config
unless File.exists?("config/host/auth_secret.exs") do
  Mix.raise("You need to configure your dev environment. See `config/host/auth_secret.exs` for an example.\r\n")
end

import_config("auth_secret.exs")

# Configure your our system.
# Default implementation needs no special stuff.
config :farmbot, :init, [
]

# Transports.
config :farmbot, :transport, [
  Farmbot.BotState.Transport.GenMqtt
]


# Configure Farmbot Behaviours.
config :farmbot, :behaviour, [
  authorization: Farmbot.Bootstrap.Authorization,

  # uncomment this line if you have a real arduino plugged in. You will also need
  # ensure the config for `:uart_handler` is correct.
  # firmware_handler: Farmbot.Firmware.UartHandler,
  firmware_handler: Farmbot.Host.FirmwareHandlerStub,
  system_tasks: Farmbot.Host.SystemTasks
]
