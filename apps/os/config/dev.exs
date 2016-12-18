use Mix.Config
config :farmbot, state_path: "/tmp"
import_config "hardware/#{Mix.Project.config[:target]}/hardware.exs"
