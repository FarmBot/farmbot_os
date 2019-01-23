defmodule Farmbot.System.ConfigStorage.Migrations.AddEapSettings do
  use Ecto.Migration

  def change do
    alter table("network_interfaces") do
      add(:identity, :string)
      add(:password, :string)
    end
  end
end
