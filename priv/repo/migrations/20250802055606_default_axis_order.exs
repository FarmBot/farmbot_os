defmodule FarmbotOS.Asset.Repo.Migrations.DefaultAxisOrder do
  use Ecto.Migration

  def change do
    alter table("fbos_configs") do
      add(:default_axis_order, :string)
    end

    execute(
      "UPDATE fbos_configs SET updated_at = \'1970-11-07 16:52:31.618000\';"
    )
  end
end
