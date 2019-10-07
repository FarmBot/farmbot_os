defmodule FarmbotCore.Asset.Repo.Migrations.AddBootSequenceIdToFbosConfig do
  use Ecto.Migration

  def change do
    alter table("fbos_configs") do
      add(:boot_sequence_id, :id)
    end
  end
end
