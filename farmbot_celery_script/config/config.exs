use Mix.Config

if Mix.env() == :test do
  config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
    sys_calls: FarmbotCeleryScript.TestSupport.TestSysCalls
else
  config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
    sys_calls: FarmbotCeleryScript.SysCalls.Stubs
end
