defmodule FarmbotCore.Config.Repo.Migrations.AddEnigmasTable do
  use Ecto.Migration

  def change do
    create table("enigmas", primary_key: false) do
      add(:uuid, :binary_id, primary_key: true)
      add(:problem_tag, :string)
      add(:priority, :integer)
      add(:created_at, :utc_datetime)
    end
  end
end
