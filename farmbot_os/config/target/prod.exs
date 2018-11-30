use Mix.Config

config :nerves_network, regulatory_domain: "US"

config :shoehorn,
  init: [:nerves_runtime, :nerves_firmware_ssh, :farmbot_core, :farmbot_ext],
  app: :farmbot

config :tzdata, :autoupdate, :disabled

config :farmbot_core, Elixir.Farmbot.AssetWorker.Farmbot.Asset.PinBinding,
  gpio_handler: Farmbot.PinBindingWorker.CircuitsGPIOHandler,
  error_retry_time_ms: 30_000

config :farmbot_core, Farmbot.Leds, gpio_handler: Farmbot.Target.Leds.CircuitsHandler

config :farmbot_core, :behaviour, celery_script_io_layer: Farmbot.OS.IOLayer

data_path = Path.join("/", "root")

config :farmbot, Farmbot.OS.FileSystem, data_path: data_path

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
  database: Path.join(data_path, "asset-#{Mix.env()}.sqlite3")

config :farmbot,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo]

config :farmbot, Farmbot.System.Init.Supervisor,
  init_children: [
    Farmbot.Target.Leds.AleHandler
  ]

config :farmbot, Farmbot.Platform.Supervisor,
  platform_children: [
    Farmbot.System.NervesHub,
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
