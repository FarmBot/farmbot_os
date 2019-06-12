# Mocking for FarmbotCore
Mox.defmock(FarmbotCore.Asset.Query, for: FarmbotCore.Asset.Query)
Mox.defmock(FarmbotCore.Asset.Command, for: FarmbotCore.Asset.Command)

# Mocking for FarmbotExt
Mox.defmock(FarmbotExt.API, for: FarmbotExt.API)
Mox.defmock(FarmbotExt.AMQP.ConnectionWorker, for: FarmbotExt.AMQP.ConnectionWorker)
timeout = System.get_env("EXUNIT_TIMEOUT")

if timeout do
  ExUnit.start(assert_receive_timeout: String.to_integer(timeout))
else
  ExUnit.start()
end
