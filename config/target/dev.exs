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

# Configure your our init system.
config :farmbot, :init, [
  # Load consolidated protocols
  Farmbot.Target.Protocols,
  # Autodetects if a Arduino is plugged in and configures accordingly.
  Farmbot.Firmware.UartHandler.AutoDetector,

  # Allows for first boot configuration.
  Farmbot.Target.Bootstrap.Configurator,

  # Start up Network
  Farmbot.Target.Network,
  # Wait for time time come up.
  Farmbot.Target.Network.WaitForTime
]

# Transports.
config :farmbot, :transport, [
  Farmbot.BotState.Transport.GenMqtt
]

# Configure Farmbot Behaviours.
config :farmbot, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization,
  system_tasks: Farmbot.Target.SystemTasks,
  firmware_handler: Farmbot.Firmware.StubHandler

config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(Path.join(System.user_home!(), ".ssh/id_rsa.pub"))
  ]

config :bootloader,
  init: [:nerves_runtime],
  app: :farmbot
