use Mix.Config

config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
  sys_calls: FarmbotCeleryScript.SysCalls.Stubs

config :farmbot_core, FarmbotCore.FirmwareOpenTask, attempt_threshold: 5

config :farmbot_core, FarmbotCore.AssetWorker.FarmbotCore.Asset.FbosConfig,
  firmware_flash_attempt_threshold: 5
