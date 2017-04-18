use Mix.Config

app = Mix.Project.config[:app]
config app,
  configurator_port: System.get_env("CONFIGURATOR_PORT") || 5000,
  tty: System.get_env("ARDUINO_TTY")
