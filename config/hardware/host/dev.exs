use Mix.Config

# dev environment doesn't need any special init stuff.
config :farmbot, :init, []

# Configure Farmbot Behaviours.
config :farmbot, :behaviour,
  # Should implement Farmbot.System behaviour.
  system_tasks:  Farmbot.Host.SystemTasks

import_config "../../auth_secret.exs"
