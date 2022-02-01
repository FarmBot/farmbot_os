import Config

data_path = Path.join(["/", "tmp", "farmbot"])
File.mkdir_p(data_path)

config :farmbot, data_path: data_path

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [FarmbotOS.Platform.Host.Configurator]

config :logger, backends: [:console]
