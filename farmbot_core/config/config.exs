use Mix.Config

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmEvent, checkup_time_ms: 10_000

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.RegimenInstance,
  checkup_time_ms: 10_000

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.Private.Alert,
  error_retry_time_ms: 10_000

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmwareInstallation,
  error_retry_time_ms: 30_000,
  install_dir: "/tmp/farmware"

config :farmbot_core, FarmbotCore.FarmwareRuntime, runtime_dir: "/tmp/farmware_runtime"

config :farmbot_core, Elixir.FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler,
  error_retry_time_ms: 30_000

config :farmbot_core, FarmbotCore.AssetMonitor, checkup_time_ms: 30_000

config :farmbot_core, FarmbotCore.Leds, gpio_handler: FarmbotCore.Leds.StubHandler

config :farmbot_core, FarmbotCore.JSON, json_parser: FarmbotCore.JSON.JasonParser

config :farmbot_core, FarmbotCore.BotState.FileSystem,
  root_dir: "/tmp/farmbot",
  sleep_time: 200

config :farmbot_core, FarmbotCore.EctoMigrator,
  expected_fw_versions: ["6.4.2.F", "6.4.2.R", "6.4.2.G"],
  default_firmware_io_logs: false,
  default_server: "https://my.farm.bot",
  default_dns_name: "my.farm.bot",
  default_ntp_server_1: "0.pool.ntp.org",
  default_ntp_server_2: "1.pool.ntp.org",
  default_currently_on_beta:
    String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta")

import_config "ecto.exs"
import_config "logger.exs"
import_config "#{Mix.env()}.exs"
