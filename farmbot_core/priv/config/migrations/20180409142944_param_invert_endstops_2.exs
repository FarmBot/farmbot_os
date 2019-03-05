defmodule FarmbotCore.Config.Repo.Migrations.ParamInvertEndstops2 do
  use Ecto.Migration
  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_hw_param("movement_invert_2_endpoints_x")
    create_hw_param("movement_invert_2_endpoints_y")
    create_hw_param("movement_invert_2_endpoints_z")
  end
end
