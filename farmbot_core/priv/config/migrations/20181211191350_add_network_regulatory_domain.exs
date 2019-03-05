defmodule FarmbotCore.Config.Migrations.AddNetworkRegulatoryDomain do
  use Ecto.Migration

  def change do
    alter table("network_interfaces") do
      add(:regulatory_domain, :string, default: "US")
    end
  end
end
