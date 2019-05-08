use Mix.Config

list_of_configs = [
  %{
    mod: FarmbotExt.API.Preloader,
    key: :preloader_impl,
    fake: MockPreloader,
    real: FarmbotExt.API.Preloader.HTTP
  }
]

which_impl_to_use =
  if Mix.env() == :test do
    :fake
  else
    :real
  end

Enum.map(list_of_configs, fn %{mod: mod, key: key, fake: fake, real: real} = conf ->
  config :farmbot_ext, mod, [{key, Map.fetch!(conf, which_impl_to_use)}]
end)

config :logger, handle_otp_reports: true, handle_sasl_reports: true

config :farmbot_celery_script, FarmbotCeleryScript.SysCalls,
  sys_calls: FarmbotCeleryScript.SysCalls.Stubs

import_config "ecto.exs"
import_config "farmbot_core.exs"
import_config "lagger.exs"
