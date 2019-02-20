use Mix.Config
config :logger, handle_otp_reports: true, handle_sasl_reports: true

config :farmbot_ext, Farmbot.AMQP.NervesHubTransport,
  handle_nerves_hub_msg: Farmbot.Ext.HandleNervesHubMsg

config :farmbot_celery_script, Farmbot.CeleryScript.SysCalls,
  sys_calls: Farmbot.CeleryScript.SysCalls.Stubs

import_config "ecto.exs"
import_config "farmbot_core.exs"
import_config "lagger.exs"
