Mox.defmock(MockPreloader, for: FarmbotExt.API.Preloader)
Mox.defmock(MockConnectionWorker, for: FarmbotExt.AMQP.ConnectionWorker.Network)
Mox.defmock(MockQuery, for: FarmbotCore.Asset.Query)

ExUnit.start()
