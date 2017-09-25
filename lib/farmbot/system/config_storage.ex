defmodule Farmbot.System.ConfigStorage do
  @moduledoc "Repo for storing config data."
  use Ecto.Repo, otp_app: :farmbot, adapter: Sqlite.Ecto2
  import Ecto.Query, only: [from: 2]
  alias Farmbot.System.ConfigStorage.{Group, Config, BoolValue}

  def get_config_value(type, group_name, key_name)
  def get_config_value(:bool, group_name, key_name) do
    [group_id] = (from g in Group, where: g.group_name == ^group_name, select: g.id) |> all()
    [type_id]  = (from c in Config, where: c.group_id == ^group_id and c.key == ^key_name, select: c.bool_value_id) |> all()
    [val] = (from v in BoolValue, where: v.id == ^type_id, select: v) |> all()
    val
  end

  def update_config_value(type, group_name, key_name, value)

  def update_config_value(:bool, group_name, key_name, value) do
    get_config_value(:bool, group_name, key_name)
    |> Map.put(:value, value)
    |> BoolValue.changeset()
    |> update!()
  end


  #TODO Clean this up, implement other two types etc.
end
