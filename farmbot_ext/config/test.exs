use Mix.Config

if Mix.env() == :test do
  config :farmbot_ext, FarmbotExt, children: []
  config :farmbot_ext, FarmbotExt.Bootstrap.Supervisor, children: []
end
