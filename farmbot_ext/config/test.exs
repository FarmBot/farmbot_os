use Mix.Config

if Mix.env() == :test do
  config :ex_unit, capture_logs: true
  mapper = fn mod -> config :farmbot_ext, mod, children: [] end

  list = [
    FarmbotExt,
    FarmbotExt.AMQP.ChannelSupervisor,
    FarmbotExt.API.DirtyWorker.Supervisor,
    FarmbotExt.API.EagerLoader.Supervisor,
    FarmbotExt.Bootstrap.Supervisor
  ]

  Enum.map(list, mapper)
end
