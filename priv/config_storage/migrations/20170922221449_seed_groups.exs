defmodule Farmbot.System.ConfigStorage.Migrations.SeedGroups do
  use Ecto.Migration
  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.{Config, Group, StringValue, BoolValue, FloatValue}
  import Ecto.Query, only: [from: 2]

  @group_names ["authorization", "hardware_params", "settings", "user_env"]

  def change do
    populate_config_groups()
    populate_config_values()
  end

  defp populate_config_groups do
    for name <- @group_names do
      %Group{group_name: name}
      |> Group.changeset()
      |> ConfigStorage.insert()
    end
  end

  defp populate_config_values do
    for name <- @group_names do
      [group_id] =
        from(g in Group, where: g.group_name == ^name, select: g.id) |> ConfigStorage.all()

      populate_config_values(name, group_id)
    end
  end

  defp populate_config_values("authorization", group_id) do
    create_value(StringValue, "https://my.farmbot.io") |> create_config(group_id, "server")
    create_value(StringValue, nil) |> create_config(group_id, "email")
    create_value(StringValue, nil) |> create_config(group_id, "password")
    create_value(StringValue, nil) |> create_config(group_id, "token")
    create_value(StringValue, nil) |> create_config(group_id, "last_shutdown_reason")
  end

  defp populate_config_values("hardware_params", group_id) do
  end

  defp populate_config_values("settings", group_id) do
    create_value(BoolValue, false)  |> create_config(group_id, "os_auto_update")
    create_value(BoolValue, true)   |> create_config(group_id, "first_boot")
    create_value(BoolValue, true)   |> create_config(group_id, "first_sync")
    create_value(StringValue, "A")  |> create_config(group_id, "current_repo")
    create_value(BoolValue, true)   |> create_config(group_id, "first_party_farmware")
    create_value(BoolValue, false)  |> create_config(group_id, "auto_sync")
    create_value(StringValue, nil)  |> create_config(group_id, "firmware_hardware")
    create_value(StringValue, nil)  |> create_config(group_id, "timezone")
    fpf_url = Application.get_env(:farmbot, :farmware)[:first_part_farmware_manifest_url]
    create_value(StringValue, fpf_url) |> create_config(group_id, "first_party_farmware_url")
  end

  defp populate_config_values("user_env", group_id) do
  end

  defp create_config(value, group_id, key) do
    %Config{group_id: group_id, key: key}
    |> Map.put(
         :"#{Module.split(value.__struct__) |> List.last() |> Macro.underscore()}_id",
         value.id
       )
    |> Config.changeset()
    |> ConfigStorage.insert!()
  end

  defp create_value(type, val \\ nil) do
    unless Code.ensure_loaded?(type) do
      raise "Unknown type: #{type}"
    end

    type
    |> struct()
    |> Map.put(:value, val)
    |> type.changeset()
    |> ConfigStorage.insert!()
  end
end
