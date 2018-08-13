use Mix.Config

config :farmbot, data_path: "/root"

# Disable tzdata autoupdates because it tries to dl the update file
# Before we have network or ntp.
config :tzdata, :autoupdate, :disabled

config :farmbot, Farmbot.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "/root/repo-#{Mix.env()}.sqlite3"

config :farmbot, Farmbot.System.ConfigStorage,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "/root/config-#{Mix.env()}.sqlite3"

config :logger_backend_ecto, LoggerBackendEcto.Repo,
  adapter: Sqlite.Ecto2,
  database: "/root/debug_logs.sqlite3"

config :farmbot, ecto_repos: [Farmbot.Repo, Farmbot.System.ConfigStorage]

# Configure your our init system.
config :farmbot, :init, [
  Farmbot.Target.Leds.AleHandler,

  # Autodetects if a Arduino is plugged in and configures accordingly.
  Farmbot.Firmware.UartHandler.AutoDetector,

  # Allows for first boot configuration.
  Farmbot.Target.Bootstrap.Configurator,

  # Start up Network
  Farmbot.Target.Network,

  # Wait for time time come up.
  Farmbot.Target.Network.WaitForTime,

  # Stops the disk from getting full.
  Farmbot.Target.Network.TzdataTask,

  # Reports SOC temperature to BotState.
  Farmbot.Target.SocTempWorker,
  # Reports Wifi info to BotState.
  Farmbot.Target.Network.InfoSupervisor,

  # Helps with hot plugging of serial devices.
  Farmbot.Target.Uevent.Supervisor,
]

config :farmbot, :transport, [
  Farmbot.BotState.Transport.AMQP,
  Farmbot.BotState.Transport.HTTP,
  Farmbot.BotState.Transport.Registry,
]

# Configure Farmbot Behaviours.
config :farmbot, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization,
  system_tasks: Farmbot.Target.SystemTasks,
  firmware_handler: Farmbot.Firmware.StubHandler,
  update_handler: Farmbot.Target.UpdateHandler,
  pin_binding_handler: Farmbot.Target.PinBinding.AleHandler,
  leds_handler: Farmbot.Target.Leds.AleHandler

config :shoehorn,
  init: [:nerves_runtime],
  handler: Farmbot.ShoehornHandler,
  app: :farmbot
