defmodule Farmbot.Logger.Repo.Migrations.AddLogBuffer do
  use Ecto.Migration

  def change do
    create table("logs") do
      add(:message, :text)
      add(:level, :string)
      add(:verbosity, :integer)
      add(:meta, :string)
      add(:function, :string)
      add(:file, :string)
      add(:line, :integer)
      add(:module, :string)
      add(:version, :string)
      add(:commit, :string)
      add(:target, :string)
      add(:env, :string)
      timestamps()
    end
  end
end
