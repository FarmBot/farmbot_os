defmodule FarmbotCore.Asset.Repo.Migrations.RenamePersistentRegimensToRegimenInstances do
  use Ecto.Migration

  def change do
    rename(table(:persistent_regimens), to: table(:regimen_instances))
  end
end
