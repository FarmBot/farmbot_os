use Mix.Config
config :logger, handle_otp_reports: true, handle_sasl_reports: true
import_config "ecto.exs"
import_config "farmbot_core.exs"
import_config "lagger.exs"
