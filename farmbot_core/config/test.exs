use Mix.Config
config :logger, level: :debug
config :logger, :console, level: :warn

# must be lower than other timers
# To ensure other timers have time to timeout
config :farmbot_core, FarmbotCore.AssetMonitor, checkup_time_ms: 500

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmEvent,
  checkup_time_ms: 1000

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.RegimenInstance,
  checkup_time_ms: 1000

config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
  sys_calls: FarmbotCeleryScript.SysCalls.Stubs

if Mix.env() == :test do
  config :ex_unit, capture_logs: true
  mapper = fn mod -> config :farmbot_core, mod, children: [] end

  list = [
    FarmbotCore,
    FarmbotCore.StorageSupervisor,
    FarmbotCore.Asset.Supervisor,
    FarmbotCore.BotState.Supervisor,
    FarmbotCore.Config.Supervisor
  ]

  Enum.map(list, mapper)
end
