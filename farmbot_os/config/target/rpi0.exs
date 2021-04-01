use Mix.Config

config :farmbot_core, FarmbotCore.FirmwareOpenTask, attempt_threshold: 5_000_000

config :farmbot, FarmbotOS.Init.Supervisor,
  init_children: [
    FarmbotOS.Platform.Target.RTCWorker
  ]
