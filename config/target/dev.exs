use Mix.Config

config :farmbot, Farmbot.Repo.A,
  adapter: Sqlite.Ecto2,
  database: "/root/repo-#{Mix.env()}-A.sqlite3"

config :farmbot, Farmbot.Repo.B,
  adapter: Sqlite.Ecto2,
  database: "/root/repo-#{Mix.env()}-B.sqlite3"

config :farmbot, Farmbot.System.ConfigStorage,
  adapter: Sqlite.Ecto2,
  database: "/root/config-#{Mix.env()}.sqlite3"

config :farmbot, data_path: "/root"

# Configure your our system.
# Default implementation needs no special stuff.
config :farmbot, :init, [
  Farmbot.Target.Bootstrap.Configurator,

  # Start up Network
  Farmbot.Target.Network
]

# Transports.
config :farmbot, :transport, [
  Farmbot.BotState.Transport.GenMqtt
]

# Configure Farmbot Behaviours.
config :farmbot, :behaviour, [
  authorization: Farmbot.Bootstrap.Authorization,
  system_tasks: Farmbot.Target.SystemTasks,
  firmware_handler: Farmbot.Firmware.UartHandler
]

config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))
  ]

config :bootloader,
  init: [:nerves_runtime],
  app: :farmbot
