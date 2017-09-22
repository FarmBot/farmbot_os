defmodule Farmbot.System.ConfigStorage.Migrations.AddEAVTables do
  use Ecto.Migration

  def change do

    # "network", "authorization", etc
    create table("config_groups") do
      add :name, :string
    end

    # Name of the key
    create table("config_keys") do
      add :name, :string
    end

    ## POSSIBLE TYPES
    create table("config_value_numbers") do
      add :value, :float
    end

    create table("config_value_strings") do
      add :value, :string
    end

    create table("config_value_booleans") do
      add :value, :boolean
    end

    # How to find the things
    create table("configs") do
      add :config_group_id,   :id
      add :config_key_id,     :id
      add :config_value_id,   :id
      add :config_value_type, :string
    end
  end

end
