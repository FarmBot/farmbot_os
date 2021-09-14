defmodule FarmbotCore.Asset.Repo.Migrations.AddDeviceLocationAttrs do
  use Ecto.Migration

  def change do
    alter table("devices") do
      add(:lat, :float)
      add(:lng, :float)
      add(:indoor, :boolean)
    end

    # will resync the firmware params
    execute("UPDATE devices SET updated_at = \"1970-11-07 16:52:31.618000\"")
  end
end
