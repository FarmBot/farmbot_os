use Mix.Config
config :farmbot,
  configurator_port: System.get_env("CONFIGURATOR_PORT") || 5000,
  tty: System.get_env("ARDUINO_TTY")
