defmodule FarmbotCore.Asset.Repo.Migrations.CalibrationRetryFieldFix do
  use Ecto.Migration

  # I made a typo in the previous migration.
  def change do
    execute(
      "UPDATE firmware_configs SET updated_at = \"1970-11-07 16:52:31.618000\""
    )
  end
end
