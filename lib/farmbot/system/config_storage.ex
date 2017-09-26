defmodule Farmbot.System.ConfigStorage do
  @moduledoc "Repo for storing config data."
  use Ecto.Repo, otp_app: :farmbot, adapter: Sqlite.Ecto2
  import Ecto.Query, only: [from: 2]
  alias Farmbot.System.ConfigStorage.{Group, Config, BoolValue, FloatValue, StringValue}

  @doc "Please be careful with this. It uses a lot of queries."
  def get_config_as_map do
    groups = (from g in Group, select: g) |> all()
    Map.new(groups, fn(group) ->
      vals = (from b in Config, where: b.group_id == ^group.id, select: b) |> all()
      s = Map.new(vals, fn(val) ->
        [value] = Enum.find_value(val |> Map.from_struct, fn({_key, _val} = f) ->
          case f do
            {:bool_value_id,   id} when is_number(id) -> all(from v in BoolValue, where: v.id == ^id, select: v.value)
            {:float_value_id,  id} when is_number(id) -> all(from v in FloatValue, where: v.id == ^id, select: v.value)
            {:string_value_id, id} when is_number(id) -> all(from v in StringValue, where: v.id == ^id, select: v.value)
            _ -> false
          end
        end)
        {val.key, value}
      end)
      {group.group_name, s}
    end)
  end

  def get_config_value(type, group_name, key_name) when type in [:bool, :float, :string] do
    __MODULE__
    |> apply(:"get_#{type}_value", [group_name, key_name])
    |> Map.fetch!(:value)
  end

  def update_config_value(type, group_name, key_name, value) when type in [:bool, :float, :string] do
    __MODULE__
    |> apply(:"get_#{type}_value", [group_name, key_name])
    |> Ecto.Changeset.change(value: value)
    |> update!()
  end

  def get_bool_value(group_name, key_name) do
    group_id = get_group_id(group_name)
    [type_id]  = (from c in Config, where: c.group_id == ^group_id and c.key == ^key_name, select: c.bool_value_id) |> all()
    [val] = (from v in BoolValue, where: v.id == ^type_id, select: v) |> all()
    val
  end

  def get_float_value(group_name, key_name) do
    group_id = get_group_id(group_name)
    [type_id]  = (from c in Config, where: c.group_id == ^group_id and c.key == ^key_name, select: c.float_value_id) |> all()
    [val] = (from v in FloatValue, where: v.id == ^type_id, select: v) |> all()
    val
  end

  def get_string_value(group_name, key_name) do
    group_id = get_group_id(group_name)
    [type_id]  = (from c in Config, where: c.group_id == ^group_id and c.key == ^key_name, select: c.string_value_id) |> all()
    [val] = (from v in StringValue, where: v.id == ^type_id, select: v) |> all()
    val
  end

  defp get_group_id(group_name) do
    [group_id] = (from g in Group, where: g.group_name == ^group_name, select: g.id) |> all()
    group_id
  end
end
