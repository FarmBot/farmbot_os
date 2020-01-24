timeout = System.get_env("EXUNIT_TIMEOUT")

Mimic.copy(FarmbotCore.Asset.Query)
Mimic.copy(FarmbotExt.API)
Mimic.copy(FarmbotExt.AMQP.ConnectionWorker)
Mimic.copy(FarmbotCeleryScript.SysCalls.Stubs)

if timeout do
  ExUnit.start(assert_receive_timeout: String.to_integer(timeout))
else
  ExUnit.start()
end
