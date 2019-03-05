defmodule FarmbotCore.Config.Repo.Migrations.AddSecretField do
  use Ecto.Migration
  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_auth_config("secret", :string, nil)
  end
end
