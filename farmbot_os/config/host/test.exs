use Mix.Config

data_path = Path.join(["/", "tmp", "farmbot"])
File.mkdir_p(data_path)

config :farmbot_core,
  data_path: data_path

config :farmbot,
  platform_children: [
    {Farmbot.Platform.Host.Configurator, []}
  ]

config :farmbot, FarmbotOS.Configurator,
  data_layer: FarmbotOS.Configurator.ConfigDataLayer,
  network_layer: FarmbotOS.Configurator.FakeNetworkLayer

config :plug, :validate_header_keys_during_test, true

config :ex_unit, capture_logs: true
