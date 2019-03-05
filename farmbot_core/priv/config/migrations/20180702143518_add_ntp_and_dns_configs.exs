defmodule FarmbotCore.Config.Repo.Migrations.AddNtpAndDnsConfigs do
  use Ecto.Migration
  import FarmbotCore.Config.MigrationHelpers

  @default_ntp_server_1 Application.get_env(:farmbot_core, FarmbotCore.EctoMigrator)[
                          :default_ntp_server_1
                        ]
  @default_ntp_server_2 Application.get_env(:farmbot_core, FarmbotCore.EctoMigrator)[
                          :default_ntp_server_2
                        ]
  @default_dns_name Application.get_env(:farmbot_core, FarmbotCore.EctoMigrator)[
                      :default_dns_name
                    ]

  @config_error """
  config :farmbot_core, FarmbotCore.EctoMigrator, [
    default_ntp_server_1: "0.pool.ntp.org",
    default_ntp_server_2: "1.pool.ntp.org",
    default_dns_name: "my.farm.bot"
  ]
  """

  if is_nil(@default_ntp_server_1),
    do: raise(@config_error)

  if is_nil(@default_ntp_server_2),
    do: raise(@config_error)

  if is_nil(@default_dns_name),
    do: raise(@config_error)

  def change do
    create_settings_config("default_ntp_server_1", :string, @default_ntp_server_1)
    create_settings_config("default_ntp_server_2", :string, @default_ntp_server_2)
    create_settings_config("default_dns_name", :string, @default_dns_name)
  end
end
