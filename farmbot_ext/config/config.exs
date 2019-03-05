use Mix.Config
config :logger, handle_otp_reports: true, handle_sasl_reports: true

config :farmbot_ext, FarmbotExt.AMQP.NervesHubTransport,
  handle_nerves_hub_msg: FarmbotExt.HandleNervesHubMsg

config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
  sys_calls: FarmbotCeleryScript.SysCalls.Stubs

import_config "ecto.exs"
import_config "farmbot_core.exs"
import_config "lagger.exs"
