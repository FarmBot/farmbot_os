defmodule Farmbot.System.ConfigStorage.Migrations.AddSyncCmdTable do
  use Ecto.Migration

  def change do
    create table("sync_cmds") do
      add(:remote_id, :integer)
      add(:kind, :string)
      add(:body, :string)
      timestamps()
    end
  end
end
