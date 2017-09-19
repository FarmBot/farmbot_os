use Mix.Config

config :farmbot, Farmbot.Repo,
  adapter: Sqlite.Ecto2,
  database: "/root/#{Mix.env()}.sqlite3"

config :farmbot, data_path: "/root"

# Configure your our system.
# Default implementation needs no special stuff.
config :farmbot, :init, [
  # Run migrations and whatnot.
  Farmbot.Target.Ecto,

  # initialize the configuration.
  # This bring up a captive portal if needed.
  Farmbot.Bootstrap.Configurator,

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
  system_tasks: Farmbot.Target.SystemTasks
]

config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))
  ]

config :bootloader,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: :farmbot
