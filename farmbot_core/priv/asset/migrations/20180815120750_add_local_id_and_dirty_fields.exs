defmodule Farmbot.Asset.Repo.Migrations.AddLocalIdAndDirtyFields do
  use Ecto.Migration

  def change do
    alter table("devices") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("farm_events") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("farmware_installations") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("farmware_envs") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("peripherals") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("pin_bindings") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("points") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("regimens") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("sensors") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("sequences") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    alter table("tools") do
      add(:local_id, :uuid, primary: true)
      add(:dirty, :boolean, default: false)
    end

    # TODO(Connor) - 2018-08-15 All things without a UUID will probably need one?
    # However first HTTP sync will wipe out all assets, and redownload them
    # So i guess not?
  end

end
