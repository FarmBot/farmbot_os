Application.ensure_all_started(:farmbot)
timeout = System.get_env("EXUNIT_TIMEOUT")

Mimic.copy(AMQP.Channel)
Mimic.copy(FarmbotCeleryScript.SysCalls.Stubs)
Mimic.copy(FarmbotCore.Asset.Command)
Mimic.copy(FarmbotCore.Asset.Query)
Mimic.copy(FarmbotCore.BotState)
Mimic.copy(FarmbotCore.LogExecutor)
Mimic.copy(FarmbotExt.AMQP.ConnectionWorker)
Mimic.copy(FarmbotExt.API.Preloader)
Mimic.copy(FarmbotExt.API)
Mimic.copy(FarmbotExt.API.EagerLoader.Supervisor)

if timeout do
  ExUnit.start(assert_receive_timeout: String.to_integer(timeout))
else
  ExUnit.start()
end
