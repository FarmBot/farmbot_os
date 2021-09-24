use Mix.Config
config :tesla, adapter: Tesla.Adapter.Hackney

config :logger, handle_otp_reports: true, handle_sasl_reports: true

# TODO(Rick) We probably don't need to use this anymore now that Mox is a thing.
config :farmbot_core, FarmbotCeleryScript.SysCalls, sys_calls: FarmbotCeleryScript.SysCalls.Stubs

repos = [FarmbotCore.Config.Repo, FarmbotCore.Logger.Repo, FarmbotCore.Asset.Repo]
config :farmbot_core, ecto_repos: repos
config :farmbot_ext, ecto_repos: repos

config :ecto, json_library: FarmbotCore.JSON

config :farmbot_core, FarmbotCore.Config.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "config.#{Mix.env()}.db",
  priv: "../farmbot_core/priv/config"

config :farmbot_core, FarmbotCore.Logger.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "logger.#{Mix.env()}.db",
  priv: "../farmbot_core/priv/logger"

config :farmbot_core, FarmbotCore.Asset.Repo,
  adapter: Sqlite.Ecto2,
  loggers: [],
  database: "asset.#{Mix.env()}.db",
  priv: "../farmbot_core/priv/asset"

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler

config :farmbot_core, Elixir.FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey,
  ssh_handler: FarmbotCore.PublicKeyHandler.StubSSHHandler

config :farmbot_core, FarmbotCore.BotState.FileSystem, root_dir: "/tmp/farmbot_state"

config :farmbot_core, FarmbotCore.Leds, gpio_handler: FarmbotCore.Leds.StubHandler

config :farmbot_core, FarmbotCore.JSON, json_parser: FarmbotCore.JSON.JasonParser

config :farmbot_core, FarmbotCore.Core.CeleryScript.RunTimeWrapper,
  celery_script_io_layer: FarmbotCore.Core.CeleryScript.StubIOLayer

config :farmbot_core, FarmbotCore.EctoMigrator,
  default_firmware_io_logs: false,
  default_server: "https://my.farm.bot",
  default_dns_name: "my.farm.bot",
  default_ntp_server_1: "0.pool.ntp.org",
  default_ntp_server_2: "1.pool.ntp.org",
  default_currently_on_beta:
    String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta")

is_test? = Mix.env() == :test

config :farmbot_ext, FarmbotExt.Time, disable_timeouts: is_test?

if is_test? do
  config :ex_unit, capture_logs: true
  mapper = fn mod -> config :farmbot_ext, mod, children: [] end

  list = [
    FarmbotExt,
    FarmbotExt.MQTT.Supervisor,
    FarmbotExt.MQTT.ChannelSupervisor,
    FarmbotExt.API.DirtyWorker.Supervisor,
    FarmbotExt.API.EagerLoader.Supervisor,
    FarmbotExt.Bootstrap.Supervisor
  ]

  Enum.map(list, mapper)
end
