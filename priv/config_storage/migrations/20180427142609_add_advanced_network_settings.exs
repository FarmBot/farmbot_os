defmodule Farmbot.System.ConfigStorage.Migrations.AddAdvancedNetworkSettings do
  use Ecto.Migration

  def change do
    alter table(:network_interfaces) do
      add(:ipv4_address, :string)
      add(:ipv4_gateway, :string)
      add(:ipv4_subnet_mask, :string)
      add(:domain, :string)
      add(:name_servers, :string)
    end
  end
end
