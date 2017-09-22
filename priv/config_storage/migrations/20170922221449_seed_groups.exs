defmodule Farmbot.System.ConfigStorage.Migrations.SeedGroups do
  use Ecto.Migration
  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.ConfigGroup
  alias ConfigStorage.ConfigKey

  def change do
    populate_config_groups()
    populate_config_keys()
    # populate_default_values()
  end

  defp populate_config_groups do
    group_names = ["network", "authorization", "hardware", "hardware_params", "settings"]
    for name <- group_names do
      %ConfigGroup{name: name}
      |> ConfigGroup.changeset()
      |> ConfigStorage.insert()
    end
  end

  defp populate_config_keys do
    auth_keys     = ["email", "password", "token", "server"]
    hardware_keys = ["custom_firmware"]
    settings_keys = ["firmware_hardware", "timezone", "os_auto_update", "first_party_farmware"]
    network_keys  = ["ntp", "ssh"]

    for key <- auth_keys ++ hardware_keys ++ settings_keys ++ network_keys do
      %ConfigKey{name: key}
      |> ConfigKey.changeset()
      |> ConfigStorage.insert()
    end
  end

  defp populate_default_values do

  end
end
