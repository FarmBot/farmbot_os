use Mix.Config

# Configure your our system.
# Default implementation needs no special stuff.
config :farmbot, :init, [
  # Farmbot.Bootstrap.Configurator
]

# Transports.
config :farmbot, :transport, [
  Farmbot.BotState.Transport.GenMqtt
]


# Configure Farmbot Behaviours.
config :farmbot, :behaviour, [
  authorization: Farmbot.Bootstrap.Authorization,
  firmware_handler: Farmbot.Firmware.UartHandler,
  system_tasks: Farmbot.Host.SystemTasks
]

config :farmbot, :uart_handler, [
  tty: "/dev/ttyACM0"
]

config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))
  ]

config :bootloader,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: :farmbot
