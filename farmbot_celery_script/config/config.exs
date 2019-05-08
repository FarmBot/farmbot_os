use Mix.Config

if Mix.env() == :test do
  config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
    sys_calls: Farmbot.TestSupport.CeleryScript.TestSysCalls
else
  config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
    sys_calls: FarmbotCeleryScript.SysCalls.Stubs
end

import_config "../../global_configs.exs"
