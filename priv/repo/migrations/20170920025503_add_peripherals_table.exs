defmodule Farmbot.Repo.Migrations.AddPeripheralsTable do
  use Ecto.Migration

  def change do
    create table("peripherals", primary_key: false) do
      add :id, :integer
      add :pin, :integer
      add :mode, :integer
      add :label, :string
    end
    create unique_index("peripherals", [:id])
  end
end
