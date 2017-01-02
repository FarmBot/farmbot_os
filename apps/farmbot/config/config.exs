use Mix.Config

target = Mix.Project.config[:target]
mqtt_transport = Farmbot.Transport.GenMqtt

# I force colors because they are important.
config :logger, :console,
  colors: [enabled: true],
  utc_logs: true

# Iex needs colors too.
config :iex, :colors,
  enabled: true

# send a message to these modules when we successfully log in.
config :farmbot_auth, callbacks: [mqtt_transport]

# frontend <-> bot transports.
config :farmbot, transports: [mqtt_transport]

# Move this?
config :quantum, cron: [ "5 1 * * *": {Farmbot.Updates.Handler, :do_update_check}]

# Import configuration specific to out environment.
import_config "#{Mix.env}.exs"
# import config specific to our nerves_target
IO.puts "using #{target} configuration."
import_config "hardware/#{target}/hardware.exs"
