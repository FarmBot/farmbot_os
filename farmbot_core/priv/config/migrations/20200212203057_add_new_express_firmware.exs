defmodule FarmbotCore.Config.Repo.Migrations.AddNewExpressFirmware do
  use Ecto.Migration

  def up do
    FarmbotCore.Config.update_config_value(
      :bool,
      "settings",
      "firmware_needs_flash",
      true
    )
  end

  def down do
    FarmbotCore.Config.update_config_value(
      :bool,
      "settings",
      "firmware_needs_flash",
      true
    )
  end
end
