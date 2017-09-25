defmodule Farmbot.System.ConfigStorage.Config do
  @moduledoc ""

  use Ecto.Schema
  import Ecto.Changeset
  alias Farmbot.System.ConfigStorage.{Group, BoolValue, FloatValue, StringValue}

  schema "configs" do
    belongs_to :group, Group
    belongs_to :string_value, StringValue
    belongs_to :bool_value, BoolValue
    belongs_to :float_value, FloatValue
    field :key, :string
  end

  @required_fields [:key, :group_id]

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
