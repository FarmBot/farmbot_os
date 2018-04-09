defmodule Farmbot.System.ConfigStorage.Migrations.ParamInvertEndstops2 do
  use Ecto.Migration
  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_hw_param("movement_invert_2_endpoints_x")
    create_hw_param("movement_invert_2_endpoints_y")
    create_hw_param("movement_invert_2_endpoints_z")
  end
end
