use Mix.Config
local_file = Path.join(System.user_home!(), ".ssh/id_rsa.pub")
local_key = if File.exists?(local_file), do: [File.read!(local_file)], else: []

config :nerves_firmware_ssh,
  authorized_keys: local_key

config :vintage_net,
  regulatory_domain: "00",
  persistence: VintageNet.Persistence.Null,
  config: [
    {"wlan0", %{type: VintageNet.Technology.Null}}
  ]

config :mdns_lite,
  mdns_config: %{
    host: :hostname,
    ttl: 120
  },
  services: [
    # service type: _http._tcp.local - used in match
    %{
      name: "Web Server",
      protocol: "http",
      transport: "tcp",
      port: 80
    },
    # service_type: _ssh._tcp.local - used in match
    %{
      name: "Secure Socket",
      protocol: "ssh",
      transport: "tcp",
      port: 22
    }
  ]

config :shoehorn,
  init: [:nerves_runtime, :vintage_net, :nerves_firmware_ssh, :farmbot_core, :farmbot_ext],
  handler: FarmbotOS.Platform.Target.ShoehornHandler,
  app: :farmbot

config :tzdata, :autoupdate, :disabled

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey,
  ssh_handler: FarmbotOS.Platform.Target.SSHConsole

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotOS.Platform.Target.PinBindingWorker.CircuitsGPIOHandler,
  # gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler,
  error_retry_time_ms: 30_000

config :farmbot_core, FarmbotCore.Leds,
  gpio_handler: FarmbotOS.Platform.Target.Leds.CircuitsHandler

data_path = Path.join("/", "root")

config :farmbot, FarmbotOS.FileSystem, data_path: data_path

config :farmbot_core, FarmbotCore.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  pool_size: 1,
  database: Path.join(data_path, "config-prod.sqlite3")

config :farmbot_core, FarmbotCore.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  pool_size: 1,
  database: Path.join(data_path, "logs-prod.sqlite3")

config :farmbot_core, FarmbotCore.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  pool_size: 1,
  database: Path.join(data_path, "asset-prod.sqlite3")

config :farmbot, FarmbotOS.Platform.Supervisor,
  platform_children: [
    FarmbotOS.Platform.Target.NervesHubClient,
    FarmbotOS.Platform.Target.Network.Supervisor,
    FarmbotOS.Platform.Target.SSHConsole,
    FarmbotOS.Platform.Target.Uevent.Supervisor,
    FarmbotOS.Platform.Target.InfoWorker.Supervisor
  ]

config :farmbot, FarmbotOS.Configurator,
  network_layer: FarmbotOS.Platform.Target.Configurator.VintageNetworkLayer

config :farmbot, FarmbotOS.System, system_tasks: FarmbotOS.Platform.Target.SystemTasks

config :nerves_hub,
  client: FarmbotOS.Platform.Target.NervesHubClient,
  remote_iex: true,
  public_keys: [File.read!("priv/staging.pub"), File.read!("priv/prod.pub")]

config :nerves_hub, NervesHub.Socket, reconnect_interval: 5_000

config :farmbot_core, FarmbotCore.FirmwareOpenTask, attempt_threshold: 5

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.FbosConfig,
  firmware_flash_attempt_threshold: 5

config :logger, backends: [RingLogger]

config :logger, RingLogger,
  max_size: 1024,
  color: [enabled: true]
