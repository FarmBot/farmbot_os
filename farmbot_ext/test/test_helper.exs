Mox.defmock(MockPreloader, for: FarmbotExt.API.Preloader)
Mox.defmock(MockConnectionWorker, for: FarmbotExt.AMQP.ConnectionWorker.Network)

ExUnit.start()
