use Mix.Config
config :farmbot,
  configurator_port: 80,
  streamer_port: 4040

config :tzdata, :data_dir, "/tmp"
config :tzdata, :autoupdate, :disabled
config :nerves_interim_wifi, regulatory_domain: "US" #FIXME
config :quantum, cron: [ "5 1 * * *": {Farmbot.Updates.Handler, :do_update_check}]
