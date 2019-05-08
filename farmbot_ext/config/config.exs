use Mix.Config

config :logger, handle_otp_reports: true, handle_sasl_reports: true

# TODO(Rick) We probably don't need to use this anymore now that Mox is a thing.
config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
  sys_calls: FarmbotCeleryScript.SysCalls.Stubs

import_config "ecto.exs"
import_config "farmbot_core.exs"
import_config "lagger.exs"
import_config "../../global_configs.exs"
