defmodule Elixir.Farmbot.Asset.Repo.Migrations.CreateSyncsTable do
  use Ecto.Migration

  def change do
    create table("syncs", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:devices, {:array, :map})
      add(:diagnostic_dumps, {:array, :map})
      add(:farm_events, {:array, :map})
      add(:farmware_envs, {:array, :map})
      add(:farmware_installations, {:array, :map})
      add(:fbos_configs, {:array, :map})
      add(:firmware_configs, {:array, :map})
      add(:peripherals, {:array, :map})
      add(:pin_bindings, {:array, :map})
      add(:points, {:array, :map})
      add(:regimens, {:array, :map})
      add(:sensor_readings, {:array, :map})
      add(:sensors, {:array, :map})
      add(:sequences, {:array, :map})
      add(:tools, {:array, :map})
      add(:now, :utc_datetime)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
