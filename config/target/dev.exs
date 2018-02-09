use Mix.Config

config :logger,
  utc_log: true,
  backends: []

config :farmbot, data_path: "/root"

config :farmbot, profile: System.get_env("FBOS_PROFILE")

# Disable tzdata autoupdates because it tries to dl the update file
# Before we have network or ntp.
config :tzdata, :autoupdate, :disabled

config :farmbot, Farmbot.Repo.A,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "/root/users/default/repo-A.sqlite3"

config :farmbot, Farmbot.Repo.B,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "/root/users/default/repo-B.sqlite3"

config :farmbot, Farmbot.System.ConfigStorage,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "/root/users/default/config.sqlite3"

config :farmbot, Farmbot.System.GlobalConfig,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "tmp/global-config.sqlite3",
  pool_size: 1

config :farmbot, ecto_repos: [Farmbot.Repo.A, Farmbot.Repo.B, Farmbot.System.ConfigStorage, Farmbot.System.GlobalConfig]

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
  Farmbot.Target.Network.WaitForTime,


  # Stops the disk from getting full.
  Farmbot.Target.Network.TzdataTask,

  # Debug stuff
  Farmbot.System.Debug,
  Farmbot.Target.Uevent.Supervisor
]

config :farmbot, :transport, [
  Farmbot.BotState.Transport.AMQP,
  Farmbot.BotState.Transport.HTTP,
]

# Configure Farmbot Behaviours.
config :farmbot, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization,
  system_tasks: Farmbot.Target.SystemTasks,
  firmware_handler: Farmbot.Firmware.StubHandler,
  update_handler: Farmbot.Target.UpdateHandler,
  gpio_handler:   Farmbot.Target.GPIO.AleHandler

config :nerves_init_gadget,
  address_method: :static

local_file = Path.join(System.user_home!(), ".ssh/id_rsa.pub")
local_key = if File.exists?(local_file) do
  [File.read!(local_file)]
else
  []
end

config :nerves_firmware_ssh, authorized_keys: local_key

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: :farmbot

config :nerves, :firmware,
  rootfs_overlay: "overlay/"
