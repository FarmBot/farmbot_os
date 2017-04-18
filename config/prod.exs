use Mix.Config

# Mix Configs
app = Mix.Project.config[:app]

config app,
  configurator_port: 80

# In production, we want a cron job for checking for updates.
config :quantum, cron: [ "5 1 * * *": {Farmbot.System.Updates, :do_update_check}]

config :nerves_interim_wifi, regulatory_domain: "US" #FIXME

# Logger
config :logger,
  backends: [
    :console,
    {ExSyslogger, :ex_syslogger_error},
    {ExSyslogger, :ex_syslogger_info}
  ]

config :logger, :ex_syslogger_error,
  level: :error,
  format: "$date $time [$level] $levelpad $metadata $message\n",
  metadata: [:module, :line, :function],
  ident: "Farmbot",
  facility: :kern,
  formatter: Farmbot.SysFormatter,
  option: [:pid, :cons]

config :logger, :ex_syslogger_info,
  level: :info,
  format: "$date $time [$level] $message\n",
  ident: "Farmbot",
  facility: :kern,
  formatter: Farmbot.SysFormatter,
  option: [:pid, :cons]
