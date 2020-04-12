defmodule FarmbotCore.Asset.Repo.Migrations.AddPulloutDirectionToPoint do
  use Ecto.Migration

  def change do
    alter table("points") do
      # 0 means "NONE"
      add(:pullout_direction, :integer, default: 0)
    end

    execute("UPDATE points SET updated_at = \"1970-11-07 16:52:31.618000\"")
  end
end
