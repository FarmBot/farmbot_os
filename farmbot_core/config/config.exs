use Mix.Config

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmEvent, checkup_time_ms: 10_000

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmwareInstallation,
  error_retry_time_ms: 30_000,
  install_dir: "/tmp/farmware"

config :farmbot_core, Farmbot.AssetMonitor, checkup_time_ms: 30_000

config :farmbot_core,
  expected_fw_versions: ["6.4.0.F", "6.4.0.R", "6.4.0.G"],
  default_server: "https://my.farm.bot",
  default_currently_on_beta:
    String.contains?(to_string(:os.cmd('git rev-parse --abbrev-ref HEAD')), "beta"),
  firmware_io_logs: false,
  farm_event_debug_log: false

# Configure Farmbot Behaviours.
config :farmbot_core, :behaviour,
  firmware_handler: Farmbot.Firmware.StubHandler,
  leds_handler: Farmbot.Leds.StubHandler,
  pin_binding_handler: Farmbot.PinBinding.StubHandler,
  celery_script_io_layer: Farmbot.Core.CeleryScript.StubIOLayer,
  json_parser: Farmbot.JSON.JasonParser

import_config "ecto.exs"
import_config "logger.exs"
import_config "#{Mix.env()}.exs"
