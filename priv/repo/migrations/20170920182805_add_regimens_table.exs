defmodule Farmbot.Repo.Migrations.AddRegimensTable do
  use Ecto.Migration

  def change do
    create table("regimens", primary_key: false) do
      add(:id, :integer)
      add(:name, :string)
    end

    create(unique_index("regimens", [:id]))
  end
end
