defmodule FarmbotOS.Asset.Repo.Migrations.BootSequenceIdAndReadAt do
  use Ecto.Migration

  def change do
    alter table("fbos_configs") do
      add(:boot_sequence_id, :integer)
    end

    alter table("sensor_readings") do
      add(:read_at, :utc_datetime_usec, null: false)
    end

    execute(
      "UPDATE fbos_configs SET updated_at = \'1970-11-07 16:52:31.618000\';"
    )

    execute(
      "UPDATE sensor_readings SET updated_at = \'1970-11-07 16:52:31.618000\';"
    )
  end
end
