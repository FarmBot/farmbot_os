use Mix.Config
local_file = Path.join(System.user_home!(), ".ssh/id_rsa.pub")
local_key = if File.exists?(local_file), do: [File.read!(local_file)], else: []

config :logger, [
  utc_log: true,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  backends: [RingLogger]
]

config :nerves_firmware_ssh,
  authorized_keys: local_key,
  ssh_console_port: 22

config :farmbot_core, :behaviour,
  firmware_handler: Farmbot.Firmware.StubHandler,
  leds_handler: Farmbot.Target.Leds.AleHandler,
  pin_binding_handler: Farmbot.Target.PinBinding.AleHandler,
  celery_script_io_layer: Farmbot.OS.IOLayer

data_path = Path.join("/", "root")
config :farmbot_ext,
  data_path: data_path

config :farmbot_core, Farmbot.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "config-#{Mix.env()}.sqlite3"),
  pool_size: 1

config :farmbot_core, Farmbot.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "logs-#{Mix.env()}.sqlite3"),
  pool_size: 1

config :farmbot_core, Farmbot.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: Path.join(data_path, "repo-#{Mix.env()}.sqlite3"),
  pool_size: 1

config :farmbot_os,
  ecto_repos: [Farmbot.Config.Repo, Farmbot.Logger.Repo, Farmbot.Asset.Repo],
  init_children: [
    {Farmbot.Target.Leds.AleHandler, []},
    {Farmbot.Firmware.UartHandler.AutoDetector, []},
  ],
  platform_children: [
    {Farmbot.Target.Bootstrap.Configurator, []},
    {Farmbot.Target.Network, []},
    {Farmbot.Target.SSHConsole, []},
    {Farmbot.Target.Network.WaitForTime, []},
    {Farmbot.Target.Network.DnsTask, []},
    {Farmbot.Target.Network.TzdataTask, []},
    # Reports Disk usage every 60 seconds.
    {Farmbot.Target.DiskUsageWorker, []},
    # Reports Memory usage every 60 seconds.
    {Farmbot.Target.MemoryUsageWorker, []},
    # Reports SOC temperature every 60 seconds.
    {Farmbot.Target.SocTempWorker, []},
    # Reports Uptime every 60 seconds.
    {Farmbot.Target.UptimeWorker, []},
    {Farmbot.Target.Network.InfoSupervisor, []},
    {Farmbot.Target.Uevent.Supervisor, []},
  ]

config :farmbot_os, :behaviour,
  update_handler: Farmbot.Target.UpdateHandler,
  system_tasks: Farmbot.Target.SystemTasks
