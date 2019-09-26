defmodule FarmbotCore.Asset.Repo.Migrations.AddPointDiscardedAt do
  use Ecto.Migration

  def change do
    alter table(:points) do
      add(:discarded_at, :utc_datetime)
    end
  end
end
