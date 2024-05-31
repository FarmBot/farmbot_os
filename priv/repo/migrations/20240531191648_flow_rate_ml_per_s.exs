defmodule FarmbotOS.Asset.Repo.Migrations.FlowRateMlPerS do
  use Ecto.Migration

  def change do
    alter table("tools") do
      add(:flow_rate_ml_per_s, :integer)
    end

    execute("UPDATE tools SET updated_at = \'1970-11-07 16:52:31.618000\';")
  end
end
