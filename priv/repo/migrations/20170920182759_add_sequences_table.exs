defmodule Farmbot.Repo.Migrations.AddSequencesTable do
  use Ecto.Migration

  def change do
    create table("sequences", primary_key: false) do
      add(:id, :integer)
      add(:name, :string)
      add(:kind, :string, default: "sequence")
      add(:args, :text)
      add(:body, :text)
    end

    create(unique_index("sequences", [:id]))
  end
end
