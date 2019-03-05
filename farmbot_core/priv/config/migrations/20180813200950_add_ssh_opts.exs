defmodule Farmbot.System.ConfigStorage.Migrations.AddSshOpts do
  use Ecto.Migration

  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("ssh_port", :float, 22.0)
    create_settings_config("authorized_ssh_key", :string, nil)
  end
end
