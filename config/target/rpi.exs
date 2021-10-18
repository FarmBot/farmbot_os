use Mix.Config

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.RTCWorker
  ]
