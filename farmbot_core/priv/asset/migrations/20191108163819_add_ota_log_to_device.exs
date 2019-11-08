defmodule FarmbotCore.Asset.Repo.Migrations.AddOtaLogToDevice do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      add(:ota_hour, :integer)
    end
  end
end
