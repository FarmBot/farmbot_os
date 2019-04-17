use Mix.Config
local_file = Path.join(System.user_home!(), ".ssh/id_rsa.pub")
local_key = if File.exists?(local_file), do: [File.read!(local_file)], else: []

config :nerves_firmware_ssh,
  authorized_keys: local_key

config :nerves_network, regulatory_domain: "US"

config :nerves_init_gadget,
  ifname: "usb0",
  address_method: :dhcpd,
  mdns_domain: "farmbot.local",
  node_name: "farmbot",
  node_host: :mdns_domain

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget, :nerves_firmware_ssh, :farmbot_core, :farmbot_ext],
  app: :farmbot

config :tzdata, :autoupdate, :disabled

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotOS.Platform.Target.PinBindingWorker.CircuitsGPIOHandler,
  # gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler,
  error_retry_time_ms: 30_000

config :farmbot_core, FarmbotCore.Leds,
  gpio_handler: FarmbotOS.Platform.Target.Leds.CircuitsHandler

data_path = Path.join("/", "root")

config :farmbot, FarmbotOS.FileSystem, data_path: data_path

config :logger_backend_ecto, LoggerBackendEcto.Repo,
  adapter: Sqlite.Ecto2,
  database: Path.join(data_path, "debug_logs.sqlite3")

config :farmbot_core, FarmbotCore.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "config-#{Mix.env()}.sqlite3")

config :farmbot_core, FarmbotCore.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "logs-#{Mix.env()}.sqlite3")

config :farmbot_core, FarmbotCore.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "asset-#{Mix.env()}.sqlite3")

config :farmbot,
  ecto_repos: [FarmbotCore.Config.Repo, FarmbotCore.Logger.Repo, FarmbotCore.Asset.Repo]

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.Leds.CircuitsHandler,
    FarmbotOS.FirmwareTTYDetector
  ]

config :farmbot, FarmbotOS.Platform.Supervisor,
  platform_children: [
    FarmbotOS.NervesHub,
    FarmbotOS.Platform.Target.Network.Supervisor,
    FarmbotOS.Platform.Target.Configurator.Supervisor,
    FarmbotOS.Platform.Target.SSHConsole,
    FarmbotOS.Platform.Target.Uevent.Supervisor,
    FarmbotOS.Platform.Target.InfoWorker.Supervisor
  ]

config :farmbot_ext, FarmbotExt.AMQP.NervesHubChannel, handle_nerves_hub_msg: FarmbotOS.NervesHub

config :farmbot, FarmbotOS.NervesHub,
  farmbot_nerves_hub_handler: FarmbotOS.Platform.Target.NervesHubClient

config :farmbot, FarmbotOS.System, system_tasks: FarmbotOS.Platform.Target.SystemTasks

config :nerves_hub,
  client: FarmbotOS.Platform.Target.NervesHubClient,
  public_keys: [File.read!("priv/staging.pub"), File.read!("priv/prod.pub")]

config :nerves_hub, NervesHub.Socket, reconnect_interval: 30_000
