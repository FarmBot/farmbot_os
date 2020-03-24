use Mix.Config

if Mix.env() == :test do
  config :farmbot_ext, FarmbotExt, children: []
end
