defmodule FarmbotCore.Asset.Repo.Migrations.AddOtaUpdateFieldsDevice do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      add(:last_ota, :utc_datetime)
      add(:last_ota_checkup, :utc_datetime)
    end
  end
end
