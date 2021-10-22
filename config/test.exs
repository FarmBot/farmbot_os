use Mix.Config

data_path = Path.join(["/", "tmp", "farmbot"])
File.mkdir_p(data_path)

config :ex_unit, capture_logs: true
config :farmbot, data_path: data_path

config :farmbot, FarmbotCore.Celery.SysCallGlue,
  sys_calls: FarmbotCore.Celery.SysCallGlue.Stubs

config :farmbot, FarmbotOS.Configurator,
  data_layer: FarmbotOS.Configurator.ConfigDataLayer,
  network_layer: FarmbotOS.Configurator.FakeNetworkLayer

config :farmbot, platform_children: [{FarmbotOS.Platform.Host.Configurator, []}]
config :plug, :validate_header_keys_during_test, true

[
  FarmbotCore,
  FarmbotCore.Config.Supervisor,
  FarmbotCore.StorageSupervisor,
  FarmbotExt,
  FarmbotExt.Bootstrap.Supervisor,
  FarmbotExt.DirtyWorker.Supervisor,
  FarmbotExt.EagerLoader.Supervisor,
  FarmbotExt.MQTT.ChannelSupervisor,
  FarmbotExt.MQTT.Supervisor
]
|> Enum.map(fn mod -> config :farmbot, mod, children: [] end)
