use Mix.Config

config :logger,
  utc_log: true,
  backends: []

config :farmbot, Farmbot.Repo.A,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "/root/repo-#{Mix.env()}-A.sqlite3"

config :farmbot, Farmbot.Repo.B,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "/root/repo-#{Mix.env()}-B.sqlite3"

config :farmbot, Farmbot.System.ConfigStorage,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "/root/config-#{Mix.env()}.sqlite3"

config :farmbot, ecto_repos: [Farmbot.Repo.A, Farmbot.Repo.B, Farmbot.System.ConfigStorage]

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
  Farmbot.Target.Network.WaitForTime,

  # Debug stuff
  Farmbot.System.Debug
]

config :farmbot, :transport, [
  Farmbot.BotState.Transport.GenMQTT,
  # Farmbot.BotState.Transport.AMQP,
  Farmbot.BotState.Transport.HTTP,
]

# Configure Farmbot Behaviours.
config :farmbot, :behaviour,
  authorization: Farmbot.Bootstrap.Authorization,
  system_tasks: Farmbot.Target.SystemTasks,
  firmware_handler: Farmbot.Firmware.StubHandler,
  update_handler: Farmbot.Target.UpdateHandler

local_file = Path.join(System.user_home!(), ".ssh/id_rsa.pub")
local_key = if File.exists?(local_file) do
  [File.read!(local_file)]
else
  []
end

travis_file = "travis_env"
travis_keys = if File.exists?(travis_file) do
  File.read!(travis_file) |> String.split(",")
else
  []
end

config :nerves_firmware_ssh, authorized_keys: local_key ++ travis_keys

config :nerves_init_gadget,
  address_method: :static

config :bootloader,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: :farmbot
