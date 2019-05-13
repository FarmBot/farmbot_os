use Mix.Config

if Mix.env() == :test do
  config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
    sys_calls: Farmbot.TestSupport.CeleryScript.TestSysCalls
else
  config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
    sys_calls: FarmbotCeleryScript.SysCalls.Stubs
end

if Mix.env() == :test do
  # Assign values used by the test suite to mock things out.
  # Leaving these values unassign results in default (production/dev) module use
  config :farmbot_ext, FarmbotExt.API.Preloader, preloader_impl: MockPreloader
  config :farmbot_ext, FarmbotExt.AMQP.ConnectionWorker, network_impl: MockConnectionWorker
end
