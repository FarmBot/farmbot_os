use Mix.Config
config :farmbot, state_path: "/tmp"
import_config "hardware_#{Mix.Project.config[:target]}.exs"
