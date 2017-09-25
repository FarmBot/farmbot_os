defmodule Farmbot.System.ConfigStorage.Migrations.SeedGroups do
  use Ecto.Migration
  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.{Config, Group, StringValue, BoolValue, FloatValue}
  import Ecto.Query, only: [from: 2]

  @group_names ["network", "authorization", "hardware", "hardware_params", "settings"]

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
    for name <- ["network"] do
      [group_id] = (from g in Group, where: g.group_name == ^name, select: g.id) |> ConfigStorage.all()
      populate_config_values(name, group_id)
    end
  end

  defp populate_config_values("network", group_id) do
    ssh_value = create_value(BoolValue, false)
    %Config{group_id: group_id,
            bool_value_id: ssh_value.id,
            key: "ssh"}
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
