defmodule Farmbot.Config.Repo.Migrations.AddSecretField do
  use Ecto.Migration
  import Farmbot.Config.MigrationHelpers

  def change do
    create_auth_config("secret", :string, nil)
  end
end
