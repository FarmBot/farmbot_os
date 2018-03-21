defmodule Farmbot.System.ConfigStorage.Migrations.AddMaybeHiddenNetworkFlag do
  use Ecto.Migration

  def change do
    alter table("network_interfaces") do
      add(:maybe_hidden, :boolean)
    end
  end
end
