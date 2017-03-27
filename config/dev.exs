use Mix.Config
config :farmbot,
  configurator_port: System.get_env("CONFIGURATOR_PORT") || 5000,
  streamer_port: System.get_env("STREAMER_PORT") || 5050,
  tty: System.get_env("ARDUINO_TTY")
