defmodule Farmbot.Config.Repo.Migrations.AddNtpAndDnsConfigs do
  use Ecto.Migration
  import Farmbot.Config.MigrationHelpers

  @default_ntp_server_1 Application.get_env(
                          :farmbot_core,
                          :default_ntp_server_1,
                          "0.pool.ntp.org"
                        )
  @default_ntp_server_2 Application.get_env(
                          :farmbot_core,
                          :default_ntp_server_2,
                          "1.pool.ntp.org"
                        )
  @default_dns_name Application.get_env(:farmbot_core, :default_dns_name, "nerves-project.org")
  if is_nil(@default_ntp_server_1),
    do: raise("Missing application env config: `:default_ntp_server_1`")

  if is_nil(@default_ntp_server_2),
    do: raise("Missing application env config: `:default_ntp_server_2`")

  if is_nil(@default_dns_name), do: raise("Missing application env config: `:default_dns_name`")

  def change do
    create_settings_config("default_ntp_server_1", :string, @default_ntp_server_1)
    create_settings_config("default_ntp_server_2", :string, @default_ntp_server_2)
    create_settings_config("default_dns_name", :string, @default_dns_name)
  end
end
