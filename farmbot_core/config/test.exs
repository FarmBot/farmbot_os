use Mix.Config
config :logger, level: :debug
config :logger, :console, level: :warn

config :farmbot_core, FarmbotCeleryScript.SysCalls,
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
