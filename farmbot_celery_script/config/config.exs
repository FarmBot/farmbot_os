use Mix.Config

if Mix.env() == :test do
  config :farmbot_celery_script, Farmbot.CeleryScript.SysCalls,
    sys_calls: Farmbot.CeleryScript.TestSupport.TestSysCalls
else
  config :farmbot_celery_script, Farmbot.CeleryScript.SysCalls,
    sys_calls: Farmbot.CeleryScript.SysCalls.Stubs
end
