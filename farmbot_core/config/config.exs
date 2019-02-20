use Mix.Config

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmEvent, checkup_time_ms: 10_000
config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.PersistentRegimen, checkup_time_ms: 10_000

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmwareInstallation,
  error_retry_time_ms: 30_000,
  install_dir: "/tmp/farmware"

config :farmbot_core, Farmbot.FarmwareRuntime, runtime_dir: "/tmp/farmware_runtime"

config :farmbot_core, Elixir.Farmbot.AssetWorker.Farmbot.Asset.PinBinding,
  gpio_handler: Farmbot.PinBindingWorker.StubGPIOHandler,
  error_retry_time_ms: 30_000

config :farmbot_core, Farmbot.AssetMonitor, checkup_time_ms: 30_000

config :farmbot_core, Farmbot.Leds, gpio_handler: Farmbot.Leds.StubHandler

config :farmbot_core, Farmbot.JSON, json_parser: Farmbot.JSON.JasonParser

config :farmbot_core, Farmbot.BotState.FileSystem,
  root_dir: "/tmp/farmbot",
  sleep_time: 200

config :farmbot_celery_script, Farmbot.CeleryScript.SysCalls,
  sys_calls: Farmbot.CeleryScript.SysCalls.Stubs

config :farmbot_core, Farmbot.EctoMigrator,
  expected_fw_versions: ["6.4.2.F", "6.4.2.R", "6.4.2.G"],
  default_firmware_io_logs: false,
  default_server: "https://my.farm.bot",
  default_currently_on_beta:
    String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta")

import_config "ecto.exs"
import_config "logger.exs"
import_config "#{Mix.env()}.exs"
