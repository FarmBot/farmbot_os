defmodule Farmbot.System.ConfigStorage.Migrations.AddFarmwareToolsCommit do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  @default_farmware_tools_release_url Application.get_env(:farmbot, :default_farmware_tools_release_url)
  if is_nil(@default_farmware_tools_release_url), do: raise("Missing application env config: `:default_farmware_tools_release_url`")

  def change do
    create_settings_config("farmware_tools_release_url", :string, @default_farmware_tools_release_url)
    create_settings_config("farmware_tools_install_commit", :string, nil)
  end
end
