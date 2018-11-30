use Mix.Config

# must be lower than other timers
# To ensure other timers have time to timeout
config :farmbot_core, Farmbot.AssetMonitor, checkup_time_ms: 500

config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.FarmEvent, checkup_time_ms: 1000
config :farmbot_core, Farmbot.AssetWorker.Farmbot.Asset.PersistentRegimen, checkup_time_ms: 1000

config :farmbot_core, Farmbot.Core.CeleryScript.RunTimeWrapper,
  celery_script_io_layer: Farmbot.TestSupport.CeleryScript.TestIOLayer
