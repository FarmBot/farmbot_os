use Mix.Config
config :logger, handle_otp_reports: true, handle_sasl_reports: true

config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
  sys_calls: FarmbotCeleryScript.SysCalls.Stubs

if Mix.env() == :test do
  config :farmbot_ext, FarmbotExt.API.Preloader, preloader_impl: MockPreloader
else
  config :farmbot_ext, FarmbotExt.API.Preloader, preloader_impl: FarmbotExt.API.Preloader.HTTP
end

import_config "ecto.exs"
import_config "farmbot_core.exs"
import_config "lagger.exs"
