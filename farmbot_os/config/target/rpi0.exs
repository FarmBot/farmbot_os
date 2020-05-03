use Mix.Config

config :farmbot_core, FarmbotCore.FirmwareOpenTask, attempt_threshold: 50

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.RTCWorker
  ]
