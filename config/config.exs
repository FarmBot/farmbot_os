use Mix.Config
import_config "#{Mix.env}.exs"

config :farmbot_auth,
  callbacks: [Farmbot.Sync, Mqtt.Handler]
