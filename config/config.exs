use Mix.Config
import_config "#{Mix.env}.exs"

config :farmbot_auth,
  callbacks: [Farmbot.Sync, Farmbot.RPC.Transport.Mqtt]

config :farmbot_configurator,
  callback: Farmbot.BotState.Monitor

config :json_rpc,
  transport: Farmbot.RPC.Transport.Mqtt,
  handler:   Farmbot.RPC.Handler

config :uart,
  baud: 115200
