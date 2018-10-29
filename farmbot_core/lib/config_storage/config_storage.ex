defmodule Farmbot.Config do
  @moduledoc "API for accessing config data."

  alias Farmbot.Config.{
    Repo,
    Config, Group, BoolValue, FloatValue, StringValue, NetworkInterface
  }

  import Ecto.Query, only: [from: 2]

  @doc "Input a network config. Takes many settings as a map."
  def input_network_config!(%{} = config) do
    Farmbot.Config.destroy_all_network_configs()
    data = struct(NetworkInterface, config)
    Repo.insert!(data)
  end

  def get_all_network_configs do
    Repo.all(NetworkInterface)
  end

  def destroy_all_network_configs do
    Repo.delete_all(NetworkInterface)
  end

  @doc "Please be careful with this. It uses a lot of queries."
  def get_config_as_map do
    groups = from(g in Group, select: g) |> Repo.all()

    Map.new(groups, fn group ->
      vals = from(b in Config, where: b.group_id == ^group.id, select: b) |> Repo.all()

      s =
        Map.new(vals, fn val ->
          [value] =
            Enum.find_value(val |> Map.from_struct(), fn {_key, _val} = f ->
              case f do
                {:bool_value_id, id} when is_number(id) ->
                  Repo.all(from(v in BoolValue, where: v.id == ^id, select: v.value))

                {:float_value_id, id} when is_number(id) ->
                  Repo.all(from(v in FloatValue, where: v.id == ^id, select: v.value))

                {:string_value_id, id} when is_number(id) ->
                  Repo.all(from(v in StringValue, where: v.id == ^id, select: v.value))

                _ ->
                  false
              end
            end)

          {val.key, value}
        end)

      {group.group_name, s}
    end)
  end

  def get_config_value(:string, "authorization", key_name) do
    env = System.get_env("FARMBOT_#{String.upcase(key_name)}")
    if env && env != "" do
      env
    else
      __MODULE__
      |> apply(:get_string_value, ["authorization", key_name])
      |> Map.fetch!(:value)
    end
  end

  def get_config_value(type, group_name, key_name) when type in [:bool, :float, :string] do
    __MODULE__
    |> apply(:"get_#{type}_value", [group_name, key_name])
    |> Map.fetch!(:value)
  end

  def get_config_value(type, _, _) do
    raise "Unsupported type: #{type}"
  end

  def update_config_value(type, group_name, key_name, value) when type in [:bool, :float, :string] do
    __MODULE__
    |> apply(:"get_#{type}_value", [group_name, key_name])
    |> Ecto.Changeset.change(value: value)
    |> Repo.update!()
    |> dispatch(group_name, key_name)
  end

  def update_config_value(type, _, _, _) do
    raise "Unsupported type: #{type}"
  end

  def get_bool_value(group_name, key_name) do
    group_id = get_group_id(group_name)

    case from(
           c in Config,
           where: c.group_id == ^group_id and c.key == ^key_name,
           select: c.bool_value_id
         )
         |> Repo.all() do
      [type_id] ->
        [val] = from(v in BoolValue, where: v.id == ^type_id, select: v) |> Repo.all()
        val

      [] ->
        raise "no such key #{key_name}"
    end
  end

  def get_float_value(group_name, key_name) do
    group_id = get_group_id(group_name)

    [type_id] =
      from(
        c in Config,
        where: c.group_id == ^group_id and c.key == ^key_name,
        select: c.float_value_id
      )
      |> Repo.all()

    [val] = from(v in FloatValue, where: v.id == ^type_id, select: v) |> Repo.all()
    val
  end

  def get_string_value(group_name, key_name) do
    group_id = get_group_id(group_name)
    [type_id] =
      from(
        c in Config,
        where: c.group_id == ^group_id and c.key == ^key_name,
        select: c.string_value_id
      )
      |> Repo.all()

    [val] = from(v in StringValue, where: v.id == ^type_id, select: v) |> Repo.all()
    val
  end

  defp get_group_id(group_name) do
    [group_id] = from(g in Group, where: g.group_name == ^group_name, select: g.id) |> Repo.all()
    group_id
  end

  defp dispatch(%{value: value} = val, group, key) do
    Farmbot.Registry.dispatch(__MODULE__, {group, key, value})
    val
  end
end
