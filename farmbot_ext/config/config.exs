use Mix.Config
config :farmbot_ext, :behaviour, authorization: Farmbot.Bootstrap.Authorization
import_config "ecto.exs"
import_config "farmbot_core.exs"
import_config "lagger.exs"
