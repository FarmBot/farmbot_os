defmodule FarmbotCore.Logger.Repo.Migrations.AddMessageHashToLogsTable do
  use Ecto.Migration

  def change do
    alter table("logs") do
      add(:hash, :binary)
      add(:duplicates, :integer)
    end
  end
end
