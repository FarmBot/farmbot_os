use Mix.Config
config :logger, handle_otp_reports: true, handle_sasl_reports: true

config :farmbot_ext, Farmbot.AMQP.NervesHubTransport,
  handle_nerves_hub_msg: Farmbot.Ext.HandleNervesHubMsg

import_config "ecto.exs"
import_config "farmbot_core.exs"
import_config "lagger.exs"
