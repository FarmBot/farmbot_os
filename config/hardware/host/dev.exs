use Mix.Config

# dev environment doesn't need any special init stuff.
config :farmbot, :init, []

config :farmbot, :transport, [
  Farmbot.BotState.Transport.GenMqtt
]

# Configure Farmbot Behaviours.
config :farmbot, :behaviour,
  # Should implement Farmbot.System behaviour.
  system_tasks:  Farmbot.Host.SystemTasks

import_config "../../auth_secret.exs"
