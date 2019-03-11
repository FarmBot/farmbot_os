use Mix.Config

config :logger,
  handle_otp_reports: false,
  handle_sasl_reports: false

config :lager, :error_logger_redirect, false
config :lager, :error_logger_whitelist, []
config :lager, :crash_log, false

config :lager,
  handlers: [],
  extra_sinks: []
