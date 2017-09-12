use Mix.Config

unless File.exists?("config/host/auth_secret_test.exs") do
  Mix.raise("You need to configure your test environment.\r\n")
end
import_config("auth_secret_test.exs")

config :farmbot, :init, []

# Transports.
config :farmbot, :transport, []


# Configure Farmbot Behaviours.
config :farmbot, :behaviour, [
  authorization: Farmbot.Test.Authorization,
  firmware_handler: Farmbot.Host.FirmwareHandlerStub,
  system_tasks: Farmbot.Test.SystemTasks
]
