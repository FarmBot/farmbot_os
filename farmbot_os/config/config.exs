use Mix.Config
is_test? = Mix.env() == :test

config :exqlite, :json_library, FarmbotCore.JSON

config :farmbot, ecto_repos: [FarmbotCore.Asset.Repo]

config :farmbot, Elixir.FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey,
  ssh_handler: FarmbotCore.PublicKeyHandler.StubSSHHandler

config :farmbot, FarmbotCore.Asset.Repo, database: "database.#{Mix.env()}.db"

config :farmbot, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotCore.PinBindingWorker.StubGPIOHandler

config :farmbot, FarmbotCore.BotState.FileSystem, root_dir: "/tmp/farmbot_state"
config :farmbot, FarmbotCore.Celery.SysCalls, sys_calls: FarmbotOS.SysCalls

config :farmbot, FarmbotCore.Core.CeleryScript.RunTimeWrapper,
  celery_script_io_layer: FarmbotCore.Core.CeleryScript.StubIOLayer

config :farmbot, FarmbotCore.JSON, json_parser: FarmbotCore.JSON.JasonParser
config :farmbot, FarmbotCore.Leds, gpio_handler: FarmbotCore.Leds.StubHandler

config :farmbot, FarmbotExt.API.Preloader,
  preloader_impl: FarmbotExt.API.Preloader.HTTP

config :farmbot, FarmbotExt.Time, disable_timeouts: is_test?

config :farmbot, FarmbotOS.Configurator,
  network_layer: FarmbotOS.Configurator.FakeNetworkLayer

config :farmbot, FarmbotOS.FileSystem, data_path: "/tmp/farmbot"

config :farmbot, FarmbotOS.Platform.Supervisor,
  platform_children: [FarmbotOS.Platform.Host.Configurator]

config :farmbot, FarmbotOS.System,
  system_tasks: FarmbotOS.Platform.Host.SystemTasks

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"
config :tesla, adapter: Tesla.Adapter.Hackney

rollbar_token = System.get_env("ROLLBAR_TOKEN")

if rollbar_token && Mix.env() != :test do
  IO.puts("=== ROLLBAR IS ENABLED! ===")

  config :rollbax,
    access_token: rollbar_token,
    environment: "production",
    enable_crash_reports: true,
    custom: %{fbos_version: Mix.Project.config()[:version]}
else
  config :rollbax, enabled: false
end

if Mix.target() == :host do
  if File.exists?("config/host/#{Mix.env()}.exs") do
    import_config("host/#{Mix.env()}.exs")
  end
else
  import_config("target/#{Mix.env()}.exs")

  import_config("target/#{Mix.target()}.exs")
end
