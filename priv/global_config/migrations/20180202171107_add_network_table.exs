defmodule Farmbot.System.GlobalConfig.Migrations.AddNetworkTable do
  use Ecto.Migration

  def change do
    create table("network_interfaces") do
      add(:name, :string, null: false)
      add(:type, :string, null: false)

      add(:ssid, :string)
      add(:psk, :string)
      add(:security, :string)

      add(:ipv4_method, :string)
    end
  end
end
