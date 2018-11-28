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
  handler: Farmbot.ShoehornHandler,
  app: :farmbot

config :tzdata, :autoupdate, :disabled

config :farmbot_core, :behaviour,
  firmware_handler: Farmbot.Firmware.StubHandler,
  leds_handler: Farmbot.Target.Leds.AleHandler,
  pin_binding_handler: Farmbot.Target.PinBinding.AleHandler,
  celery_script_io_layer: Farmbot.OS.IOLayer,
  json_parser: Farmbot.JSON.JasonParser

data_path = Path.join("/", "root")

config :farmbot_ext,
  data_path: data_path

config :logger_backend_ecto, LoggerBackendEcto.Repo,
  adapter: Sqlite.Ecto2,
  database: Path.join(data_path, "debug_logs.sqlite3")

config :farmbot_core, Farmbot.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "config-#{Mix.env()}.sqlite3")

config :farmbot_core, Farmbot.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "logs-#{Mix.env()}.sqlite3")

config :farmbot_core, Farmbot.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "repo-#{Mix.env()}.sqlite3")

config :farmbot,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo]

config :farmbot, Farmbot.System.Init.Supervisor,
  init_children: [
    Farmbot.Target.Leds.AleHandler
    # {Farmbot.Firmware.UartHandler.AutoDetector, []}
  ]

config :farmbot, Farmbot.Platform.Supervisor,
  platform_children: [
    Farmbot.Target.Network.Supervisor,
    Farmbot.Target.Configurator.Supervisor,
    Farmbot.Target.SSHConsole,
    Farmbot.Target.Uevent.Supervisor,
    Farmbot.Target.InfoWorker.Supervisor
  ]

config :farmbot, Farmbot.System, system_tasks: Farmbot.Target.SystemTasks

config :farmbot, Farmbot.System.NervesHub,
  farmbot_nerves_hub_handler: Farmbot.System.NervesHubClient

config :nerves_hub,
  client: Farmbot.System.NervesHubClient,
  public_keys: [File.read!("priv/staging.pub"), File.read!("priv/prod.pub")]

config :nerves_hub, NervesHub.Socket, reconnect_interval: 5_000
