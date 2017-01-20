use Mix.Config
config :nerves, :firmware,
  rootfs_additions: "config/hardware/#{Mix.Project.config[:target]}/rootfs-additions"

config :farmbot_configurator, port: 80
config :tzdata, :data_dir, "/tmp"
config :tzdata, :autoupdate, :disabled
config :nerves_interim_wifi,
  regulatory_domain: "US" #FIXME
config :quantum, cron: [ "5 1 * * *": {Farmbot.Updates.Handler, :do_update_check}]
