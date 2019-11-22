defmodule FarmbotCore.Asset.Repo.Migrations.AddMountedToolIdToDeviceTable do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      add(:mounted_tool_id, :integer)
    end
  end
end
