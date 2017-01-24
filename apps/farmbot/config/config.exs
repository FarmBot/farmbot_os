use Mix.Config

target = Mix.Project.config[:target]
mqtt_transport = Farmbot.Transport.GenMqtt
farmware_transport = Farmbot.Transport.Farmware

config :logger,
  utc_log: true

# I force colors because they are important.
config :logger, :console,
  colors: [enabled: true]


# Iex needs colors too.
config :iex, :colors, enabled: true

# send a message to these modules when we successfully log in.
config :farmbot_auth, callbacks: [mqtt_transport]

# frontend <-> bot transports.
config :farmbot, transports: [mqtt_transport, farmware_transport]

# Move this?

# Import configuration specific to out environment.
import_config "#{Mix.env}.exs"
# import config specific to our nerves_target
IO.puts "using #{target} configuration."
import_config "hardware/#{target}/hardware.exs"

# config :ex_json_schema,
  # :remote_schema_resolver,
  # fn url -> HTTPoison.get!(url).body |> Poison.decode! end
