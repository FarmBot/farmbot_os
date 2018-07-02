defmodule Farmbot.System.ConfigStorage.Migrations.AddNtpAndDnsConfigs do
  use Ecto.Migration
  import Farmbot.System.ConfigStorage.MigrationHelpers

  @default_ntp_server_1 Application.get_env(:farmbot, :default_ntp_server_1)
  @default_ntp_server_2 Application.get_env(:farmbot, :default_ntp_server_2)
  @default_dns_name Application.get_env(:farmbot, :default_dns_name)
  if is_nil(@default_ntp_server_1), do: raise("Missing application env config: `:default_ntp_server_1`")
  if is_nil(@default_ntp_server_2), do: raise("Missing application env config: `:default_ntp_server_2`")
  if is_nil(@default_dns_name), do: raise("Missing application env config: `:default_dns_name`")

  def change do
    create_settings_config("default_ntp_server_1", :string, @default_ntp_server_1)
    create_settings_config("default_ntp_server_2", :string, @default_ntp_server_2)
    create_settings_config("default_dns_name", :string, @default_dns_name)
  end
end
