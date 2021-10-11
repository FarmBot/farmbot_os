use Mix.Config
config :logger, level: :debug
config :logger, :console, level: :warn

config :farmbot_core, FarmbotCore.Celery.SysCalls,
  sys_calls: FarmbotCore.Celery.SysCalls.Stubs

if Mix.env() == :test do
  config :ex_unit, capture_logs: true
  mapper = fn mod -> config :farmbot_core, mod, children: [] end

  list = [
    FarmbotCore,
    FarmbotCore.Asset.Supervisor,
    FarmbotCore.BotState.Supervisor,
    FarmbotCore.Config.Supervisor,
    FarmbotCore.StorageSupervisor,
    FarmbotExt,
    FarmbotExt.Bootstrap.Supervisor,
    FarmbotExt.DirtyWorker.Supervisor,
    FarmbotExt.EagerLoader.Supervisor,
    FarmbotExt.MQTT.ChannelSupervisor,
    FarmbotExt.MQTT.Supervisor
  ]

  Enum.map(list, mapper)
  config :ex_unit, capture_logs: true
end
