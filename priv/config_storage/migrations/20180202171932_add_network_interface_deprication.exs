defmodule Farmbot.System.ConfigStorage.Migrations.AddNetworkInterfaceDeprication do
  use Ecto.Migration

  def change do
    alter table("network_interfaces") do
      add(:migrated, :boolean)
    end
  end
end
