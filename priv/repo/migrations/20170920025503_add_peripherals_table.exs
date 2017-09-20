defmodule Farmbot.Repo.Migrations.AddPeripheralsTable do
  use Ecto.Migration

  def change do
    create table("peripherals", primary_key: false) do
      add :id, :integer
      add :pin, :integer
      add :mode, :integer
      add :label, :string
      add :created_at, :utc_datetime
      add :updated_at, :utc_datetime
    end
  end
end
