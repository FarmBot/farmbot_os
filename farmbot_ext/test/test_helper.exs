timeout = System.get_env("EXUNIT_TIMEOUT")

if timeout do
  ExUnit.start(assert_receive_timeout: String.to_integer(timeout))
else
  ExUnit.start()
end

Mimic.copy(FarmbotCore.Asset.Query)
Mimic.copy(FarmbotExt.API)
Mimic.copy(FarmbotExt.AMQP.ConnectionWorker)
