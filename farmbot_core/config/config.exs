use Mix.Config

is_test? = Mix.env() == :test

config :exqlite, :json_library, FarmbotCore.JSON
config :farmbot_core, FarmbotCore.Config.Repo, database: "config.#{Mix.env()}.db"
config :farmbot_core, FarmbotCore.Logger.Repo, database: "logger.#{Mix.env()}.db"
config :farmbot_core, FarmbotCore.Asset.Repo, database:  "asset.#{Mix.env()}.db"
config :farmbot_core, ecto_repos: [FarmbotCore.Config.Repo, FarmbotCore.Logger.Repo, FarmbotCore.Asset.Repo]

config :farmbot_core,
       Elixir.FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey,
       ssh_handler: FarmbotCore.PublicKeyHandler.StubSSHHandler

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler

config :farmbot_core, FarmbotCore.BotState.FileSystem,
  root_dir: "/tmp/farmbot_state"

config :farmbot_core, FarmbotCore.BotState.FileSystem, root_dir: "/tmp/farmbot"

config :farmbot_core, FarmbotCore.Celery.SysCalls,
  sys_calls: FarmbotCore.Celery.SysCalls.Stubs

config :farmbot_core, FarmbotCore.Core.CeleryScript.RunTimeWrapper,
  celery_script_io_layer: FarmbotCore.Core.CeleryScript.StubIOLayer

config :farmbot_core, FarmbotCore.JSON,
  json_parser: FarmbotCore.JSON.JasonParser

config :farmbot_core, FarmbotCore.Leds,
  gpio_handler: FarmbotCore.Leds.StubHandler

config :farmbot_core, FarmbotExt.Time, disable_timeouts: is_test?
config :logger, handle_otp_reports: true, handle_sasl_reports: true
config :tesla, adapter: Tesla.Adapter.Hackney

import_config "#{Mix.env()}.exs"
