defmodule Farmbot.System.ConfigStorage.Migrations.AddNetworkInterfaceDeprication do
  use Ecto.Migration

  def change do
    change table(:network_interface) do
      add(:migrated, :bool)
    end
  end
end
