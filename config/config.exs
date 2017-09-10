use Mix.Config

# Mix configs.
target = Mix.Project.config[:target]
env    = Mix.env()

config :logger, utc_log: true

config :ssl, protocol_version: :"tlsv1.2"

# I force colors because they are important.
config :logger, :console,
  colors: [enabled: true, info: :cyan],
  metadata: [:module],
  format: "$time $metadata[$level] $levelpad$message\n"

# Iex needs colors too.
config :iex, :colors, enabled: true

# This is usually in the `priv` dir of :tzdata, but our fs is read only.
config :tzdata, :data_dir, "/tmp"
config :tzdata, :autoupdate, :disabled

# Path for the `fs` module to watch.
config :fs, path: "/tmp/images"

# Configure your our system.
# Default implementation needs no special stuff.
config :farmbot, :init, [
  Farmbot.Bootstrap.Configurator
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
