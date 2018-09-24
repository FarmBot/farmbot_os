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

config :farmbot, ecto_repos: [Farmbot.Repo, Farmbot.System.ConfigStorage]

config :logger, LoggerBackendSqlite, [
  database: "/root/debug_logs.sqlite3",
  max_logs: 10000
]

# Configure your our init system.
config :farmbot, :init, [
  Farmbot.Target.Leds.AleHandler,

  # Autodetects if a Arduino is plugged in and configures accordingly.
  Farmbot.Firmware.UartHandler.AutoDetector,

  # Allows for first boot configuration.
  Farmbot.Target.Bootstrap.Configurator,

  # Handles OTA updates from NervesHub
  Farmbot.System.NervesHubClient,

  # Start up Network
  Farmbot.Target.Network,

  # SSH Console.
  Farmbot.Target.SSHConsole,

  # Wait for DNS resolution
  Farmbot.Target.Network.DnsTask,

  # Stops the disk from getting full.
  Farmbot.Target.Network.TzdataTask,

  # Reports Disk usage every 60 seconds.
  Farmbot.Target.DiskUsageWorker,

  # Reports Memory usage every 60 seconds.
  Farmbot.Target.MemoryUsageWorker,

  # Reports SOC temperature every 60 seconds.
  Farmbot.Target.SocTempWorker,

  # Reports Uptime every 60 seconds.
  Farmbot.Target.UptimeWorker,

  # Reports Wifi info to BotState.
  Farmbot.Target.Network.InfoSupervisor,

  # Debug stuff
  Farmbot.System.Debug,
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
  leds_handler: Farmbot.Target.Leds.AleHandler,
  nerves_hub_handler: Farmbot.System.NervesHubClient

local_file = Path.join(System.user_home!(), ".ssh/id_rsa.pub")
local_key = if File.exists?(local_file), do: [File.read!(local_file)], else: []

config :nerves_network, regulatory_domain: "US"
config :nerves_firmware_ssh, authorized_keys: local_key

config :nerves_init_gadget,
  ifname: "usb0",
  address_method: :dhcpd,
  mdns_domain: "farmbot.local",
  node_name: nil,
  node_host: :mdns_domain

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget, :nerves_firmware_ssh],
  handler: Farmbot.ShoehornHandler,
  app: :farmbot
