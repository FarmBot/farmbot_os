use Mix.Config

# must be lower than other timers
# To ensure other timers have time to timeout
config :farmbot_core, FarmbotCore.AssetMonitor, checkup_time_ms: 500

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmEvent, checkup_time_ms: 1000

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.PersistentRegimen,
  checkup_time_ms: 1000

config :farmbot_core, FarmbotCore.CeleryScript.RunTimeWrapper,
  celery_script_io_layer: FarmbotCore.TestSupport.CeleryScript.TestIOLayer
