defmodule Farmbot.System.ConfigStorage.BoolValue do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "bool_values" do
    field(:value, :boolean)
  end

  @required_fields []

  def changeset(config, params \\ %{}) do
    config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
