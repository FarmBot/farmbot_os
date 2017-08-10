use Mix.Config

config :farmbot, :init, [

]

# Configure Farmbot Behaviours.
config :farmbot, :behaviour,
  # Should implement Farmbot.Bootstrap.Authorization behaviour.
  authorization: Farmbot.Host.Authorization,
  # Should implement Farmbot.System behaviour.
  system_tasks:  Farmbot.Host.System
