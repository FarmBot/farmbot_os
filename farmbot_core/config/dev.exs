use Mix.Config

config :farmbot_core, FarmbotCore.Celery.SysCalls,
  sys_calls: FarmbotCore.Celery.SysCalls.Stubs
