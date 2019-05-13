use Mix.Config

list_of_configs = [
  %{
    consumer: FarmbotExt.API.Preloader,
    name: :preloader_impl,
    test: MockPreloader,
    prod: FarmbotExt.API.Preloader.HTTP
  },
  %{
    consumer: FarmbotExt.AMQP.ConnectionWorker,
    name: :network_impl,
    test: MockConnectionWorker,
    prod: FarmbotExt.AMQP.ConnectionWorker.Network
  }
]

which_impl_to_use =
  if Mix.env() == :test do
    :test
  else
    :prod
  end

mapper = fn %{consumer: mod, name: name} = conf ->
  config :farmbot_ext, mod, [{name, Map.fetch!(conf, which_impl_to_use)}]
end

Enum.map(list_of_configs, mapper)
