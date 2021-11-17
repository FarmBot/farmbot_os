defmodule FarmbotOS.Asset.Repo.Migrations.PinReport do
  use Ecto.Migration

  def change do
    alter table("firmware_configs") do
      add(:pin_report_1_pin_nr, :float)
      add(:pin_report_2_pin_nr, :float)
    end

    execute(
      "UPDATE firmware_configs SET updated_at = \'1970-11-07 16:52:31.618000\';"
    )
  end
end
