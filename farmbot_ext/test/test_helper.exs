ExUnit.start()
Mox.defmock(MockPreloader, for: FarmbotExt.API.PreloaderApi)
Application.put_env(:farmbot, :preloader, MockPreloader)
