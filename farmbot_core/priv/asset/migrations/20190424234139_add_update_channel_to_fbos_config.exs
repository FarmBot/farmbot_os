defmodule FarmbotCore.Asset.Repo.Migrations.AddUpdateChannelToFbosConfig do
  use Ecto.Migration

  def change do
    alter table("fbos_configs") do
      add(:update_channel, :string)
    end
  end
end
