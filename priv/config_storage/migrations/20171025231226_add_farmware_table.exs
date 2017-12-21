defmodule Farmbot.System.ConfigStorage.Migrations.AddDevicesTable do
  use Ecto.Migration

  def change do
    create table("farmware_repositories") do
      add(:manifests, :text)
      add(:url, :string)
    end

    create(unique_index("farmware_repositories", [:url]))
  end
end
